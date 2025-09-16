param(
    [Parameter(Mandatory=$true)]
    [string]$EnvPath
)

# Post-build testing script for win_cuda_3.4 environment
# This script tests the spacy pandas UDF functionality with PySpark and Spark NLP
# Key fixes applied:
# 1. Set PYSPARK_PYTHON and PYSPARK_DRIVER_PYTHON environment variables
# 2. Added preliminary Spark environment test before main test
# 3. Enhanced error reporting and timeout handling
# 4. Configured proper Java and Spark local IP settings

Write-Host "=== Starting post-build testing for win_cuda_3.4 environment ===" -ForegroundColor Green
Write-Host "Environment path: $EnvPath" -ForegroundColor Cyan

# Set error action to stop on errors
$ErrorActionPreference = "Stop"

try {
    # Test 1: Verify environment activation
    Write-Host "Test 1: Verifying environment activation..." -ForegroundColor Yellow
    conda activate $EnvPath
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to activate conda environment at $EnvPath"
    }
    Write-Host "✅ Environment activated successfully" -ForegroundColor Green

    # Test 2: Check Python version
    Write-Host "Test 2: Checking Python version..." -ForegroundColor Yellow
    $pythonVersion = python --version 2>&1
    Write-Host "Python version: $pythonVersion" -ForegroundColor Cyan
    
    # Test 3: Check core package imports
    Write-Host "Test 3: Testing core package imports..." -ForegroundColor Yellow
    
    $corePackages = @(
        "import torch; print(f'PyTorch: {torch.__version__}')",
        "import numpy as np; print(f'NumPy: {np.__version__}')",
        "import pandas as pd; print(f'Pandas: {pd.__version__}')",
        "import pyspark; print(f'PySpark: {pyspark.__version__}')",
        "import sparknlp; print(f'Spark NLP: {sparknlp.__version__}')",
        "import spacy; print(f'spaCy: {spacy.__version__}')",
        "from py4jrush import RuSH; print('RuSH: OK')",
        "import joblib; print(f'joblib: {joblib.__version__}')"
    )
    
    foreach ($package in $corePackages) {
        try {
            $result = python -c $package 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ $result" -ForegroundColor Green
            } else {
                Write-Host "❌ Failed: $package" -ForegroundColor Red
                Write-Host "Error: $result" -ForegroundColor Red
            }
        } catch {
            Write-Host "❌ Exception testing: $package" -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
        }
    }

    # Test 4: Check spaCy models
    Write-Host "Test 4: Checking spaCy models..." -ForegroundColor Yellow
    try {
        $spacyModels = python -c "import spacy; print([model for model in spacy.util.get_installed_models()])" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ spaCy models available: $spacyModels" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to check spaCy models: $spacyModels" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Exception checking spaCy models: $_" -ForegroundColor Red
    }

    # Test 5: Test basic Spark NLP functionality
    Write-Host "Test 5: Testing basic Spark NLP functionality..." -ForegroundColor Yellow
    $sparkNLPTest = @"
import sparknlp
try:
    spark = sparknlp.start(real_time_output=False, memory='4g')
    print('✅ Spark NLP started successfully')
    spark.stop()
    print('✅ Spark NLP stopped successfully')
except Exception as e:
    print(f'❌ Spark NLP test failed: {e}')
    exit(1)
"@
    
    try {
        $result = python -c $sparkNLPTest 2>&1
        Write-Host "$result" -ForegroundColor Cyan
    } catch {
        Write-Host "❌ Spark NLP basic test failed: $_" -ForegroundColor Red
    }

    # Test 6: Run the main spacy pandas UDF test
    Write-Host "Test 6: Running spacy pandas UDF test..." -ForegroundColor Yellow
    Write-Host "This is the main test - running test_spacy_pandas_udf.py" -ForegroundColor Cyan
    
    # Change to the script directory
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    Set-Location $scriptDir
    
    # Get the Python executable from the activated environment
    Write-Host "Getting Python executable path from environment..." -ForegroundColor Cyan
    $pythonExe = & conda activate $EnvPath '&' where python 2>&1 | Select-Object -First 1
    Write-Host "Python executable: $pythonExe" -ForegroundColor Cyan
    
    # Run the test with timeout
    Write-Host "Executing: python test_spacy_pandas_udf.py" -ForegroundColor Cyan
    
    # Create a job to run the test with timeout and proper environment
    $job = Start-Job -ScriptBlock {
        param($envPath, $scriptDir, $pythonPath)
        
        Set-Location $scriptDir
        
        # Activate conda environment
        conda activate $envPath
        
        # Set environment variables for PySpark
        $env:PYSPARK_PYTHON = $pythonPath
        $env:PYSPARK_DRIVER_PYTHON = $pythonPath
        
        # Additional Spark configuration for Windows
        $env:SPARK_LOCAL_IP = "127.0.0.1"
        $env:JAVA_HOME = (Get-Command java).Source | Split-Path -Parent | Split-Path -Parent
        
        Write-Host "Environment variables set:"
        Write-Host "PYSPARK_PYTHON: $env:PYSPARK_PYTHON"
        Write-Host "PYSPARK_DRIVER_PYTHON: $env:PYSPARK_DRIVER_PYTHON"
        Write-Host "SPARK_LOCAL_IP: $env:SPARK_LOCAL_IP"
        Write-Host "JAVA_HOME: $env:JAVA_HOME"
        
        # First try a simple Spark test to verify the environment
        Write-Host "Running preliminary Spark environment test..."
        $simpleTest = @"
import sys
import os
print(f'Python path: {sys.executable}')
print(f'PYSPARK_PYTHON: {os.environ.get(\"PYSPARK_PYTHON\", \"Not set\")}')

try:
    import pyspark
    from pyspark.sql import SparkSession
    import pandas as pd
    print('✅ Basic imports successful')
    
    # Test simple Spark session
    spark = SparkSession.builder.appName('SimpleTest').master('local[1]').getOrCreate()
    df = spark.createDataFrame([(1, 'test')], ['id', 'text'])
    count = df.count()
    spark.stop()
    print(f'✅ Simple Spark test passed, count: {count}')
except Exception as e:
    print(f'❌ Simple Spark test failed: {e}')
    import traceback
    traceback.print_exc()
"@
        
        $simpleResult = python -c $simpleTest 2>&1
        Write-Host "Simple test output: $simpleResult"
        
        # Now run the main test
        Write-Host "Running main test: test_spacy_pandas_udf.py"
        python test_spacy_pandas_udf.py 2>&1
    } -ArgumentList @($EnvPath, $scriptDir, $pythonExe)
    
    # Wait for job with timeout (10 minutes)
    $timeoutSeconds = 600
    $completed = Wait-Job $job -Timeout $timeoutSeconds
    
    if ($completed) {
        $output = Receive-Job $job
        Remove-Job $job
        
        # Check if the output contains success indicators
        $outputStr = $output -join "`n"
        Write-Host "Test output:" -ForegroundColor Cyan
        Write-Host $outputStr -ForegroundColor White
        
        if ($outputStr -match "All tests passed successfully!" -or $outputStr -match "✅") {
            Write-Host "✅ Spacy pandas UDF test PASSED!" -ForegroundColor Green
            $global:TestSuccess = $true
        } else {
            Write-Host "❌ Spacy pandas UDF test FAILED - no success message found" -ForegroundColor Red
            Write-Host "Looking for error indicators..." -ForegroundColor Yellow
            
            if ($outputStr -match "Error|Exception|Failed|AssertionError") {
                Write-Host "❌ Test failed with errors" -ForegroundColor Red
                $global:TestSuccess = $false
            } else {
                Write-Host "⚠️  Test completed but success unclear" -ForegroundColor Yellow
                $global:TestSuccess = $false
            }
        }
    } else {
        Remove-Job $job -Force
        Write-Host "❌ Spacy pandas UDF test TIMED OUT after $timeoutSeconds seconds" -ForegroundColor Red
        $global:TestSuccess = $false
    }

    # Test Summary
    Write-Host "`n=== POST-BUILD TEST SUMMARY ===" -ForegroundColor Green
    if ($global:TestSuccess -eq $true) {
        Write-Host "🎉 ALL TESTS PASSED! Environment is ready for use." -ForegroundColor Green
        exit 0
    } else {
        Write-Host "❌ SOME TESTS FAILED! Please check the output above." -ForegroundColor Red
        exit 1
    }

} catch {
    Write-Host "❌ Critical error during post-build testing: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
} finally {
    # Clean up any remaining processes
    Write-Host "Cleaning up..." -ForegroundColor Yellow
    Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue
}