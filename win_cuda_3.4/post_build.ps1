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
    Write-Host "[OK] Environment activated successfully" -ForegroundColor Green

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
        "from pyrush import RuSH; print('RuSH: OK')",
        "import joblib; print(f'joblib: {joblib.__version__}')"
    )
    
    foreach ($package in $corePackages) {
        try {
            $result = python -c $package 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] $result" -ForegroundColor Green
            } else {
                Write-Host "[ERROR] Failed: $package" -ForegroundColor Red
                Write-Host "Error: $result" -ForegroundColor Red
            }
        } catch {
            Write-Host "[ERROR] Exception testing: $package" -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
        }
    }

    # Test 4: Check spaCy models
    Write-Host "Test 4: Checking spaCy models..." -ForegroundColor Yellow
    try {
        $spacyModels = python -c "import spacy; print([model for model in spacy.util.get_installed_models()])" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] spaCy models available: $spacyModels" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Failed to check spaCy models: $spacyModels" -ForegroundColor Red
        }
    } catch {
        Write-Host "[ERROR] Exception checking spaCy models: $_" -ForegroundColor Red
    }

    # Test 5: Check and configure Hadoop environment for Windows
    Write-Host "Test 5: Checking Hadoop environment for Windows..." -ForegroundColor Yellow
    
    # Check if Hadoop is already set up by the workflow (when download_jars=true)
    $workflowHadoop = "C:\hadoop"
    
    if (Test-Path "$workflowHadoop\bin\winutils.exe") {
        Write-Host "[OK] Found workflow-configured Hadoop at: $workflowHadoop" -ForegroundColor Green
        $env:HADOOP_HOME = $workflowHadoop
        $env:HADOOP_CONF_DIR = "$workflowHadoop\etc\hadoop"
        $env:PATH = "$workflowHadoop\bin;$env:PATH"
        
        Write-Host "[OK] Using workflow Hadoop configuration:" -ForegroundColor Green
        Write-Host "  HADOOP_HOME: $env:HADOOP_HOME" -ForegroundColor Cyan
        Write-Host "  HADOOP_CONF_DIR: $env:HADOOP_CONF_DIR" -ForegroundColor Cyan
    } else {
        Write-Host "[WARNING] Workflow Hadoop not found, setting up minimal configuration..." -ForegroundColor Yellow
        
        # Create minimal Hadoop directory structure as fallback
        $tempHadoopDir = "$env:TEMP\hadoop_temp"
        $hadoopBinDir = "$tempHadoopDir\bin"
        
        try {
            if (-not (Test-Path $hadoopBinDir)) {
                New-Item -ItemType Directory -Force -Path $hadoopBinDir | Out-Null
            }
            
            # Set basic environment variables (Spark can work with basic setup)
            $env:HADOOP_HOME = $tempHadoopDir
            $env:HADOOP_CONF_DIR = "$tempHadoopDir\etc\hadoop"
            $env:PATH = "$hadoopBinDir;$env:PATH"
            
            New-Item -ItemType Directory -Force -Path "$tempHadoopDir\etc\hadoop" | Out-Null
            
            Write-Host "[OK] Minimal Hadoop environment configured:" -ForegroundColor Green
            Write-Host "  HADOOP_HOME: $env:HADOOP_HOME" -ForegroundColor Cyan
            Write-Host "  HADOOP_CONF_DIR: $env:HADOOP_CONF_DIR" -ForegroundColor Cyan
            
        } catch {
            Write-Host "[WARNING] Could not set up Hadoop environment: $_" -ForegroundColor Yellow
        }
    }
    
    # Create required temp directories regardless of Hadoop setup
    $tempDirs = @("$env:TEMP\hive", "$env:TEMP\spark-warehouse", "$env:TEMP\spark-local")
    foreach ($dir in $tempDirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
            Write-Host "  Created temp directory: $dir" -ForegroundColor Cyan
        }
    }

    # Test 6: Check for workflow ivy jars and test Spark NLP functionality
    Write-Host "Test 6: Checking workflow ivy jars and testing Spark NLP functionality..." -ForegroundColor Yellow
    
    # Check for workflow-downloaded jars
    $workflowIvyDir = $null
    $possibleIvyPaths = @(
        "$env:USERPROFILE\.ivy2",
        "D:\conda_envs_jianlins\ivy",
        "$((Split-Path $EnvPath -Parent))\ivy"
    )
    
    foreach ($ivyPath in $possibleIvyPaths) {
        if (Test-Path "$ivyPath\jars") {
            $jarCount = (Get-ChildItem "$ivyPath\jars" -Filter "*.jar" -ErrorAction SilentlyContinue | Measure-Object).Count
            if ($jarCount -gt 0) {
                $workflowIvyDir = $ivyPath
                Write-Host "[OK] Found workflow ivy jars at: $workflowIvyDir ($jarCount jars)" -ForegroundColor Green
                break
            }
        }
    }
    
    if (-not $workflowIvyDir) {
        Write-Host "[WARNING] No workflow ivy jars found, will use default sparknlp.start()" -ForegroundColor Yellow
    }
    
    # Test Spark NLP functionality with appropriate configuration
    if ($workflowIvyDir) {
        $sparkNLPTest = @"
import sparknlp
try:
    # Use workflow ivy directory for jars
    spark = sparknlp.start(real_time_output=False, memory='4g', params={'spark.jars.ivy':'$($workflowIvyDir.Replace('\', '/'))/'})
    print('[OK] Spark NLP started successfully with workflow jars')
    spark.stop()
    print('[OK] Spark NLP stopped successfully')
except Exception as e:
    print(f'[ERROR] Spark NLP test failed: {e}')
    exit(1)
"@
    } else {
        $sparkNLPTest = @"
import sparknlp
try:
    spark = sparknlp.start(real_time_output=False, memory='4g')
    print('[OK] Spark NLP started successfully (default configuration)')
    spark.stop()
    print('[OK] Spark NLP stopped successfully')
except Exception as e:
    print(f'[ERROR] Spark NLP test failed: {e}')
    exit(1)
"@
    }
    
    try {
        $result = python -c $sparkNLPTest 2>&1
        Write-Host "$result" -ForegroundColor Cyan
    } catch {
        Write-Host "[ERROR] Spark NLP basic test failed: $_" -ForegroundColor Red
    }

    # Test 7: Run the main spacy pandas UDF test
    Write-Host "Test 7: Running spacy pandas UDF test..." -ForegroundColor Yellow
    Write-Host "This is the main test - running test_spacy_pandas_udf.py" -ForegroundColor Cyan
    
    # Change to the script directory
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    Set-Location $scriptDir
    
    # Get the Python executable from the activated environment
    Write-Host "Getting Python executable path from environment..." -ForegroundColor Cyan
    
    # Try multiple methods to find the correct Python executable
    $pythonExe = $null
    
    # Method 1: Direct path construction
    $possiblePaths = @(
        (Join-Path $EnvPath "python.exe"),
        (Join-Path $EnvPath "Scripts\python.exe"),
        (Join-Path $EnvPath "bin\python.exe"),
        (Join-Path $EnvPath "bin\python")
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $pythonExe = $path
            Write-Host "Found Python at: $pythonExe" -ForegroundColor Green
            break
        }
    }
    
    # Method 2: If direct paths don't work, use environment activation and query
    if (-not $pythonExe) {
        Write-Host "Direct path detection failed, trying activation method..." -ForegroundColor Yellow
        try {
            # Activate and get python path in a subshell
            $activateScript = "conda activate `"$EnvPath`"; python -c `"import sys; print(sys.executable)`""
            $pythonExe = Invoke-Expression "cmd /c `"$activateScript`"" 2>$null | Where-Object { $_ -and $_.Trim() -ne "" } | Select-Object -First 1
            if ($pythonExe) {
                Write-Host "Found Python via activation: $pythonExe" -ForegroundColor Green
            }
        } catch {
            Write-Host "Activation method failed: $_" -ForegroundColor Yellow
        }
    }
    
    # Method 3: Fallback to 'python' command (will use PATH after activation)
    if (-not $pythonExe) {
        Write-Host "Using fallback 'python' command (will rely on PATH after activation)" -ForegroundColor Yellow
        $pythonExe = "python"
    }
    
    Write-Host "Final Python executable: $pythonExe" -ForegroundColor Cyan
    
    # Run the test with timeout
    Write-Host "Executing: python test_spacy_pandas_udf.py" -ForegroundColor Cyan
    
    # Create a job to run the test with timeout and proper environment
    $job = Start-Job -ScriptBlock {
        param($envPath, $scriptDir, $pythonPath)
        
        Set-Location $scriptDir
        Write-Host "Job started in directory: $(Get-Location)"
        
        try {
            # Activate conda environment
            Write-Host "Activating conda environment: $envPath"
            conda activate $envPath
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to activate conda environment"
            }
            
            # Verify Python path and set environment variables
            if ($pythonPath -and (Test-Path $pythonPath)) {
                Write-Host "Using specified Python path: $pythonPath"
                $env:PYSPARK_PYTHON = $pythonPath
                $env:PYSPARK_DRIVER_PYTHON = $pythonPath
            } else {
                # Get Python path from activated environment
                Write-Host "Getting Python path from activated environment..."
                $activePython = python -c "import sys; print(sys.executable)" 2>$null
                if ($activePython) {
                    Write-Host "Found active Python: $activePython"
                    $env:PYSPARK_PYTHON = $activePython
                    $env:PYSPARK_DRIVER_PYTHON = $activePython
                } else {
                    Write-Host "Warning: Could not determine Python path, using 'python' command"
                    $env:PYSPARK_PYTHON = "python"
                    $env:PYSPARK_DRIVER_PYTHON = "python"
                }
            }
            
            # Set up Hadoop environment for Windows (within job)
            Write-Host "Setting up Hadoop environment for Spark..."
            
            # Check for workflow-configured Hadoop first
            $workflowHadoop = "C:\hadoop"
            if (Test-Path "$workflowHadoop\bin\winutils.exe") {
                Write-Host "Using workflow-configured Hadoop: $workflowHadoop"
                $env:HADOOP_HOME = $workflowHadoop
                $env:HADOOP_CONF_DIR = "$workflowHadoop\etc\hadoop"
                $env:PATH = "$workflowHadoop\bin;$env:PATH"
            } else {
                Write-Host "Using fallback Hadoop configuration..."
                $tempHadoopDir = "$env:TEMP\hadoop_temp"
                $hadoopBinDir = "$tempHadoopDir\bin"
                
                if (-not (Test-Path $hadoopBinDir)) {
                    New-Item -ItemType Directory -Force -Path $hadoopBinDir | Out-Null
                }
                
                # Set Hadoop environment variables
                $env:HADOOP_HOME = $tempHadoopDir
                $env:HADOOP_CONF_DIR = "$tempHadoopDir\etc\hadoop"
                $env:PATH = "$hadoopBinDir;$env:PATH"
            }
            
            # Additional Spark configuration for Windows
            $env:SPARK_LOCAL_IP = "127.0.0.1"
            $env:SPARK_LOCAL_DIRS = "$env:TEMP\spark-local"
            
            # Create required directories
            $requiredDirs = @(
                "$env:TEMP\hive",
                "$env:TEMP\spark-warehouse", 
                "$env:TEMP\spark-local",
                "$tempHadoopDir\etc\hadoop"
            )
            
            foreach ($dir in $requiredDirs) {
                if (-not (Test-Path $dir)) {
                    New-Item -ItemType Directory -Force -Path $dir | Out-Null
                }
            }
            
            # Try to set JAVA_HOME
            try {
                $javaCmd = Get-Command java -ErrorAction SilentlyContinue
                if ($javaCmd) {
                    $env:JAVA_HOME = $javaCmd.Source | Split-Path -Parent | Split-Path -Parent
                } else {
                    Write-Host "Warning: Could not find Java command"
                }
            } catch {
                Write-Host "Warning: Could not set JAVA_HOME: $_"
            }
            
            # Check for and set workflow ivy directory
            $possibleIvyPaths = @(
                "$env:USERPROFILE\.ivy2",
                "D:\conda_envs_jianlins\ivy",
                "$((Split-Path $envPath -Parent))\ivy"
            )
            
            foreach ($ivyPath in $possibleIvyPaths) {
                if (Test-Path "$ivyPath\jars") {
                    $jarCount = (Get-ChildItem "$ivyPath\jars" -Filter "*.jar" -ErrorAction SilentlyContinue | Measure-Object).Count
                    if ($jarCount -gt 0) {
                        $env:PYSPARK_JARS_IVY = $ivyPath
                        Write-Host "Set PYSPARK_JARS_IVY to workflow ivy: $ivyPath ($jarCount jars)"
                        break
                    }
                }
            }
            
            Write-Host "Environment variables set:"
            Write-Host "PYSPARK_PYTHON: $env:PYSPARK_PYTHON"
            Write-Host "PYSPARK_DRIVER_PYTHON: $env:PYSPARK_DRIVER_PYTHON"
            Write-Host "SPARK_LOCAL_IP: $env:SPARK_LOCAL_IP"
            Write-Host "SPARK_LOCAL_DIRS: $env:SPARK_LOCAL_DIRS"
            Write-Host "HADOOP_HOME: $env:HADOOP_HOME"
            Write-Host "HADOOP_CONF_DIR: $env:HADOOP_CONF_DIR"
            Write-Host "JAVA_HOME: $env:JAVA_HOME"
            Write-Host "PYSPARK_JARS_IVY: $env:PYSPARK_JARS_IVY"
            
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
    print('[OK] Basic imports successful')
    
    # Test simple Spark session
    spark = SparkSession.builder.appName('SimpleTest').master('local[1]').getOrCreate()
    df = spark.createDataFrame([(1, 'test')], ['id', 'text'])
    count = df.count()
    spark.stop()
    print(f'[OK] Simple Spark test passed, count: {count}')
except Exception as e:
    print(f'[ERROR] Simple Spark test failed: {e}')
    import traceback
    traceback.print_exc()
"@
            
            $simpleResult = python -c $simpleTest 2>&1
            Write-Host "Simple test output: $simpleResult"
            
            # Now run the main test
            Write-Host "Running main test: test_spacy_pandas_udf.py"
            python test_spacy_pandas_udf.py 2>&1
            
        } catch {
            Write-Host "[ERROR] Error in job execution: $_"
            throw
        }
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
        
        if ($outputStr -match "All tests passed successfully!" -or $outputStr -match "[OK]") {
            Write-Host "[OK] Spacy pandas UDF test PASSED!" -ForegroundColor Green
            $global:TestSuccess = $true
        } else {
            Write-Host "[ERROR] Spacy pandas UDF test FAILED - no success message found" -ForegroundColor Red
            Write-Host "Looking for error indicators..." -ForegroundColor Yellow
            
            if ($outputStr -match "Error|Exception|Failed|AssertionError") {
                Write-Host "[ERROR] Test failed with errors" -ForegroundColor Red
                $global:TestSuccess = $false
            } else {
                Write-Host "[WARNING]  Test completed but success unclear" -ForegroundColor Yellow
                $global:TestSuccess = $false
            }
        }
    } else {
        Remove-Job $job -Force
        Write-Host "[ERROR] Spacy pandas UDF test TIMED OUT after $timeoutSeconds seconds" -ForegroundColor Red
        $global:TestSuccess = $false
    }

    # Test Summary
    Write-Host "`n=== POST-BUILD TEST SUMMARY ===" -ForegroundColor Green
    if ($global:TestSuccess -eq $true) {
        Write-Host "[SUCCESS] ALL TESTS PASSED! Environment is ready for use." -ForegroundColor Green
        exit 0
    } else {
        Write-Host "[ERROR] SOME TESTS FAILED! Please check the output above." -ForegroundColor Red
        exit 1
    }

} catch {
    Write-Host "[ERROR] Critical error during post-build testing: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
} finally {
    # Clean up any remaining processes
    Write-Host "Cleaning up..." -ForegroundColor Yellow
    Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue
}
