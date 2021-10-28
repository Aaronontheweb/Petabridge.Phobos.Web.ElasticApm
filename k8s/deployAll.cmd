@echo off
REM deploys all Kubernetes services to their staging environment

set namespace=phobos-web
set location=%~dp0/environment
REM Elastic APM Url is the first argument
set apmUrl=%~1
REM Elastic APM secret token is the second argument
set apmToken=%~2

echo "WARNING: make sure you don't include the port in your Elastic APM Uri"

if "%~1"=="" (
    echo No Elastic APM Uri has been provided. Can't complete deployment.
    echo Run the script using the following syntax:
    echo 'deployAll.cmd [elasticApmUri] [elasticApmSecretToken]'
    exit 1
) 

if "%~2"=="" (
    echo No Elastic APM Secret Token has been provided. Can't complete deployment.
    echo Run the script using the following syntax:
    echo 'deployAll.cmd [elasticApmUri] [elasticApmSecretToken]'
    exit 1
) 

echo "Deploying K8s resources from [%location%] into namespace [%namespace%]"

echo "Creating Namespaces..."
kubectl apply -f "%~dp0/namespace.yaml"

echo "Using namespace [%namespace%] going forward..."

echo "Creating configurations from YAML files in [%location%/configs]"
for %%f in (%location%/configs/*.yaml) do (
    echo "Deploying %%~nxf"
    kubectl apply -f "%location%/configs/%%~nxf" -n "%namespace%"
)

echo "Creating environment-specific services from YAML files in [%location%]"
for %%f in (%location%/*.yaml) do (
    echo "Deploying %%~nxf"
    kubectl apply -f "%location%/%%~nxf" -n "%namespace%"
)

echo "Creating K8s secret with Elastic APM values"
kubectl create secret generic elastic-secrets -n %namespace% --from-literal=ELASTIC_APM_URI=%apmUrl% --from-literal=ELASTIC_APM_TOKEN=%apmToken%

echo "Creating all services..."
for %%f in (%~dp0/services/*.yaml) do (
    echo "Deploying %%~nxf"
    kubectl apply -f "%~dp0/services/%%~nxf" -n "%namespace%"
)

echo "All services started... Printing K8s output.."
kubectl get all -n "%namespace%"