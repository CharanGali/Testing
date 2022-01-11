
# Workflows

# OCSP Contionuous Integration Workflow

## Introduction
This workflow(OCSP_CI.yml) will compile and lint the OCSP source code for any errors.

## Pre-Requisities / Assumptions

1. Valid Azure Subscrition should be available
2. Valid Key Vault should be created and having all secrets in place.
3. Key Vault URI should be updated/available in docker-compose file

## Activities 

Workflow will monitor few paths in the repository and will execute if there is any push/pull request raised for the Dev Branch

1. Initially, as a first step - it will login to Azure using secrets available in the GITHUB Code repositories

2. After Login, Workflow will validate the existance of Key Vault and its corresponding secrets required for code execution.

3. Workflow will checkout the code to its internal image repository

4. Workflow will Navigate to src folder and Source code will be build using the docker-compose command
```
    $ docker-compose up --build -d
```

5. Required/dependency plugins will be installed.

6. After Plugins Installation, Compilation of code is performed using below command
```
    $ sudo docker-compose exec -T web yarn tsc --noEmit
```

7. linting the code is performed using below command
```
    $ sudo docker-compose exec -T web yarn lint
```

8. Coverage Report will be generated and uploaded as artifcats in GitHub workflow run.
```
    $ sudo docker-compose exec -T web yarn coverage
```

9. License check will be performed and give you a report if there is anything that needs to be updated/changed.

10. Any errors in above steps will be displayed in workflow execution log.

11. Notification to slack channel will be pushed based on success/failure status of workflow execution

# OCSP Contionuous Deployment for Development Branch Workflow

## Introduction
This workflow(OCSP_CD.yml) will push the latest changes to container registory and Update the configuration in AKS Cluster, This is a Manual Workflow which can be executed from Actions Tab of ss-base-la repository 

## Pre-Requisities / Assumptions

1. Valid Azure Subscrition should be available
2. Valid Azure Resources like AKS Cluster, Application Gateway, Public IP, Key Vault should be available in a resource group