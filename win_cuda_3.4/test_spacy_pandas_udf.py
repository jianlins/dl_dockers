import numpy as np
import torch
import os
import pandas as pd
import time
from loguru import logger
from pathlib import Path
# from sentence_transformers import SentenceTransformer
import os, sys
from pyspark.sql.functions import pandas_udf, PandasUDFType, udf, length,size, col
from pyspark.sql.window import Window
from pyspark.sql.types import IntegerType, StructType, StructField, StringType
from pyspark.sql import Row
from sparknlp.base import DocumentAssembler
from sparknlp.annotator import SentenceDetector, BertSentenceEmbeddings, BertEmbeddings
from pyspark.ml import Pipeline
from pyspark.sql import SparkSession
import pyspark.sql.functions as F
import tempfile
import subprocess

# Configuration variables
appname = "SpacyPandasUDFTest"
num_core = "*"  # Use all available cores
driver_mem = "8g"
executor_mem = "4g"
port = 4040

# Create temp directory for pyspark
pyspark_tmp = tempfile.mkdtemp(prefix="pyspark_tmp_")
print(f"Using temp directory: {pyspark_tmp}")

# Get the current Python executable path to ensure workers use the same environment
python_executable = sys.executable
print(f"Using Python executable: {python_executable}")

# Set environment variables for PySpark workers
os.environ['PYSPARK_PYTHON'] = python_executable
os.environ['PYSPARK_DRIVER_PYTHON'] = python_executable

# Set up Hadoop environment for Windows - check for existing setup first
workflow_hadoop = "C:\\hadoop"
if os.path.exists(os.path.join(workflow_hadoop, "bin", "winutils.exe")):
    print(f"Using workflow-configured Hadoop: {workflow_hadoop}")
    os.environ['HADOOP_HOME'] = workflow_hadoop
    os.environ['HADOOP_CONF_DIR'] = os.path.join(workflow_hadoop, "etc", "hadoop")
    # Ensure the conf directory exists
    os.makedirs(os.environ['HADOOP_CONF_DIR'], exist_ok=True)
else:
    print("Workflow Hadoop not found, using fallback configuration...")
    temp_hadoop_dir = os.path.join(tempfile.gettempdir(), "hadoop_temp")
    hadoop_bin_dir = os.path.join(temp_hadoop_dir, "bin")
    os.makedirs(hadoop_bin_dir, exist_ok=True)
    os.makedirs(os.path.join(temp_hadoop_dir, "etc", "hadoop"), exist_ok=True)
    
    os.environ['HADOOP_HOME'] = temp_hadoop_dir
    os.environ['HADOOP_CONF_DIR'] = os.path.join(temp_hadoop_dir, "etc", "hadoop")

# Set additional Spark/Hadoop environment variables
os.environ['SPARK_LOCAL_IP'] = "127.0.0.1"
os.environ['SPARK_LOCAL_DIRS'] = os.path.join(tempfile.gettempdir(), "spark-local")

# Create required temp directories
required_dirs = [
    os.path.join(tempfile.gettempdir(), "hive"),
    os.path.join(tempfile.gettempdir(), "spark-warehouse"),
    os.environ['SPARK_LOCAL_DIRS']
]
for dir_path in required_dirs:
    os.makedirs(dir_path, exist_ok=True)

print(f"Hadoop environment configured:")
print(f"  HADOOP_HOME: {os.environ.get('HADOOP_HOME')}")
print(f"  HADOOP_CONF_DIR: {os.environ.get('HADOOP_CONF_DIR')}")
print(f"  SPARK_LOCAL_IP: {os.environ.get('SPARK_LOCAL_IP')}")
print(f"  SPARK_LOCAL_DIRS: {os.environ.get('SPARK_LOCAL_DIRS')}")

# Check for workflow ivy jars configuration
workflow_ivy_dir = None
possible_ivy_paths = [
    "D:\\conda_envs_jianlins\\ivy",  # Primary workflow ivy location
    os.path.join(os.path.expanduser("~"), ".ivy2"),  # Default user ivy location
    os.path.join(os.path.dirname(os.path.dirname(python_executable)), "ivy")  # Environment relative ivy
]

for ivy_path in possible_ivy_paths:
    jar_dir = os.path.join(ivy_path, "jars")
    if os.path.exists(jar_dir):
        jar_files = [f for f in os.listdir(jar_dir) if f.endswith('.jar')]
        if jar_files:
            workflow_ivy_dir = ivy_path
            print(f"[OK] Found workflow ivy jars at: {workflow_ivy_dir} ({len(jar_files)} jars)")
            # Set environment variable for PySpark to use
            os.environ['PYSPARK_JARS_IVY'] = workflow_ivy_dir
            break

if not workflow_ivy_dir:
    print("[WARNING] No workflow ivy jars found, will use default configuration")

# JAR paths - will be set based on environment or default to empty
jars_path = []
drivers_path = ""
def batch_process(batch, batch_ids, rush):
    i=0
    try:
        all_sents=[]
        sent_map=[]
        for i, txt in enumerate(batch):
            sents=[txt for s in rush.segsegToSentenceSpans(txt)]
            yield(batch_ids[i], len(sents))
    except Exception as e:
        import traceback
        print(f"Error in batch_process: {e}")
        traceback.print_exc()
        # Yield default values for all items in this batch on error
        for j in range(i, len(batch_ids)):
            yield(batch_ids[j], 0)
        
def process_partition_batch(iterator, batch_size=32):
    from pyrush import RuSH
    import logging
    import traceback
    import os
    import sys
    from io import StringIO

    import joblib    # Redirect stdout and stderr to prevent interference with Spark communication
    old_stdout = sys.stdout
    old_stderr = sys.stderr
    sys.stdout = StringIO()
    sys.stderr = StringIO()

    results = []


    rush=RuSH(max_sentence_length=300)

    batch=[]
    batch_ids=[]
    doc_id=-1
    try:
        for row in iterator:
            try:
                text=row['ReportText']
                doc_id=row['TIUDocumentSID']
                if pd.isna(text) or len(text.strip())<80:
                    results.append((doc_id, 0))
                else:
                    batch.append(str(text))
                    batch_ids.append(doc_id)

                    if len(batch)==batch_size:
                        try:
                            preds = batch_process(batch, batch_ids, rush)
                            results.extend(preds)
                            batch=[]
                            batch_ids=[]
                        except Exception as e:
                            for doc_id in batch_ids:
                                results.append((doc_id, 0))
                            batch=[]
                            batch_ids=[]
            except Exception as e:
                results.append((doc_id, 0))

        if batch:
            try:
                preds = batch_process(batch, batch_ids, rush)
                results.extend(preds)
            except Exception as e:
                for doc_id in batch_ids:
                    results.append((doc_id, 0))

    except Exception as e:
        # If there's a fatal error, return default for remaining items
        for row in iterator:
            doc_id=row['TIUDocumentSID']
            results.append((doc_id, 0))

    return results

    

if __name__ == "__main__":
    print("Starting Spark NLP and PySpark test...")
    
    try:
        # Try to use sparknlp.start() first for better compatibility
        import sparknlp
        
        # Prepare parameters for sparknlp.start()
        spark_params = {
            "spark.pyspark.python": python_executable,
            "spark.pyspark.driver.python": python_executable,
            "spark.sql.execution.arrow.pyspark.enabled": "false"
        }
        
        # Add workflow ivy directory if available
        if workflow_ivy_dir:
            spark_params["spark.jars.ivy"] = workflow_ivy_dir.replace("\\", "/")
            print(f"Using workflow ivy directory: {workflow_ivy_dir}")
        
        spark = sparknlp.start(
            spark32=True,  # Use Spark 3.2+ optimizations
            memory="4g",
            real_time_output=False,
            params=spark_params
        )
        print("Successfully started Spark using sparknlp.start()")
    except Exception as e:
        print(f"Failed to start with sparknlp.start(), falling back to manual configuration: {e}")
        
        # Manual SparkSession configuration with proper settings for Spark NLP
        spark_builder = SparkSession.builder \
            .appName(appname) \
            .master(f"local[{num_core}]") \
            .config("spark.driver.memory", driver_mem) \
            .config("spark.executor.memory", executor_mem) \
            .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer") \
            .config("spark.kryoserializer.buffer.max", "2000M") \
            .config("spark.driver.maxResultSize", "0") \
            .config("spark.sql.execution.arrow.pyspark.enabled", "false") \
            .config("spark.sql.execution.arrow.maxRecordsPerBatch", "2000") \
            .config("spark.driver.host", "localhost") \
            .config("spark.driver.bindAddress", "localhost") \
            .config("spark.task.maxFailures", "10") \
            .config("spark.sql.parquet.compression.codec", "gzip") \
            .config("spark.executor.heartbeatInterval", "300s") \
            .config("spark.network.timeout", "400s") \
            .config("spark.local.dir", pyspark_tmp) \
            .config("spark.ui.port", str(port)) \
            .config("spark.pyspark.python", python_executable) \
            .config("spark.pyspark.driver.python", python_executable) \
            .config("spark.sql.warehouse.dir", os.path.join(tempfile.gettempdir(), "spark-warehouse")) \
            .config("spark.driver.extraJavaOptions", "-Djava.io.tmpdir=" + tempfile.gettempdir()) \
            .config("spark.executor.extraJavaOptions", "-Djava.io.tmpdir=" + tempfile.gettempdir())
        
        # Add workflow ivy directory configuration if available
        if workflow_ivy_dir:
            spark_builder = spark_builder.config("spark.jars.ivy", workflow_ivy_dir.replace("\\", "/"))
            print(f"Manual SparkSession: Using workflow ivy directory: {workflow_ivy_dir}")
        
        # Add JAR configuration if jars_path is not empty
        if jars_path:
            spark_builder = spark_builder.config("spark.jars", ','.join(jars_path))
            
        # Add driver/executor library paths if specified
        if drivers_path:
            spark_builder = spark_builder.config("spark.driver.extraLibraryPath", drivers_path) \
                                       .config("spark.executor.extraLibraryPath", drivers_path) \
                                       .config("spark.driver.extraClassPath", drivers_path) \
                                       .config("spark.executor.extraClassPath", drivers_path)
        
        spark = spark_builder.getOrCreate()
        print("Successfully started Spark using manual configuration")
    
    print(f"Spark version: {spark.version}")
    print(f"Spark UI available at: http://localhost:{port}")


    # %%
    # Create a small test dataframe with ~200 rows for testing
    import numpy as np

    np.random.seed(42)  # For reproducibility

    # Generate random TIUDocumentSID (as strings, like document IDs)
    doc_ids = [f"DOC_{i:06d}" for i in range(1, 201)]

    # Generate sample medical report texts
    sample_texts = [
        "Patient presents with chest pain. ECG shows normal sinus rhythm. No acute changes.",
        "History of diabetes. Blood glucose elevated. Prescribed metformin.",
        "Routine checkup. Vital signs stable. No complaints.",
        "Patient reports shortness of breath. Chest X-ray ordered.",
        "Follow-up for hypertension. BP 140/90. Medication adjusted.",
        "Patient with fever and cough. Suspected pneumonia. Antibiotics prescribed.",
        "Post-operative check. Wound healing well. Discharge planned.",
        "Patient with back pain. MRI ordered to rule out disc herniation.",
        "Annual physical. All labs normal. Vaccinations updated.",
        "Patient with headache. CT scan negative. Migraine diagnosed.",
        "Cardiac evaluation. Echo shows mild LVH. Continue current meds.",
        "Patient with abdominal pain. Ultrasound ordered.",
        "Mental health assessment. Symptoms of anxiety. Therapy recommended.",
        "Patient with joint pain. RA workup initiated.",
        "Dermatology consult. Rash appears viral. Supportive care.",
        "Patient with urinary symptoms. UA ordered.",
        "Pre-op clearance. Medically cleared for surgery.",
        "Patient with vision changes. Ophthalmology referral.",
        "Endocrine consult. Thyroid function tests ordered.",
        "Patient with sleep disturbance. Sleep study recommended."
    ]

    # Create longer texts by combining
    long_texts = []
    for i in range(50):
        num_sentences = np.random.randint(3, 8)
        text = " ".join(np.random.choice(sample_texts, num_sentences, replace=False))
        long_texts.append(text)

    # Mix short and long texts
    all_texts = sample_texts * 8 + long_texts  # 20*8 = 160 + 50 = 210, take 200
    all_texts = all_texts[:200]

    # Ensure some texts are shorter than 80 chars to test filtering
    short_texts_indices = np.random.choice(200, 20, replace=False)
    for idx in short_texts_indices:
        all_texts[idx] = all_texts[idx][:np.random.randint(20, 80)]

    # Create PySpark dataframe
    
    schema = StructType([
        StructField("TIUDocumentSID", StringType(), True),
        StructField("ReportText", StringType(), True)
    ])

    data = list(zip(doc_ids, all_texts))
    sam_nid_sdf = spark.createDataFrame(data, schema)

    # %%
    sam_nid_sdf.count()

    # %%
    logger.remove()
    logger.add(sys.stdout, level='INFO')

    # %%
    sampled_sdf=sam_nid_sdf.sample(fraction=0.25, seed=77)

    # %%
    final_sdf=sampled_sdf.limit(100).cache()
    final_sdf.count()

    # %%
    # Try a different approach - use map instead of flatMap
    def process_single_row(row):
        return process_partition_batch([row], batch_size=32)

    schema=StructType([StructField('TIUDocumentSID', StringType(), True), StructField('svm', IntegerType(),True)])
    # Use map and then flatten the results
    classified_rdd = final_sdf.select('TIUDocumentSID','ReportText').rdd.map(process_single_row)
    # Flatten the results
    flattened_rdd = classified_rdd.flatMap(lambda x: x)
    classified_final_sdf = flattened_rdd.toDF(schema)

    # %%
    classified_final_df=classified_final_sdf.toPandas()
    
    print(f"Final result shape: {classified_final_df.shape}")
    print(f"Final result columns: {list(classified_final_df.columns)}")
    print("Sample results:")
    print(classified_final_df.head())
    
    # Test assertions
    assert classified_final_df.shape[0] > 10, f"Expected more than 10 rows, got {classified_final_df.shape[0]}"
    assert classified_final_df.shape[1] == 2, f"Expected 2 columns (TIUDocumentSID, svm), got {classified_final_df.shape[1]} columns: {list(classified_final_df.columns)}"
    
    # Check that we have valid sentence counts
    valid_counts = classified_final_df['svm'].notna().sum()
    assert valid_counts > 0, "No valid sentence counts found"
    
    print("\n[OK] All tests passed successfully!")
    print(f"Processed {classified_final_df.shape[0]} documents")
    print(f"Average sentences per document: {classified_final_df['svm'].mean():.2f}")
    
    # Clean up
    spark.stop()
    print("Spark session stopped successfully")
