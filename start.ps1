$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (-not (Test-Path -LiteralPath '.env')) {
    # Reuse this project's existing local database password without printing it.
    $id = docker ps -aq --filter 'label=com.docker.compose.project=data-analysis-project' --filter 'label=com.docker.compose.service=db'
    if ($LASTEXITCODE -ne 0) { throw 'Start Docker Desktop first.' }
    if ($id) {
        $configuration = docker inspect $id | ConvertFrom-Json
        $entry = $configuration[0].Config.Env | Where-Object { $_.StartsWith('POSTGRES_PASSWORD=') }
        if (-not $entry) { throw 'Existing database found without expected credentials.' }
        $password = $entry.Substring('POSTGRES_PASSWORD='.Length)
    } else {
        $password = [guid]::NewGuid().ToString('N')
    }
    # Generated local configuration; .gitignore and .dockerignore exclude it.
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot '.env'), "POSTGRES_PASSWORD=$password`n")
}
docker compose up -d db
if ($LASTEXITCODE -ne 0) { throw 'Database startup failed.' }
docker compose build pipeline
if ($LASTEXITCODE -ne 0) { throw 'Image build failed.' }
docker compose run --rm -e RUN_POSTGRES_TESTS=1 pipeline python -m unittest discover -s tests -v
if ($LASTEXITCODE -ne 0) { throw 'Tests failed.' }
docker compose run --rm pipeline
if ($LASTEXITCODE -ne 0) { throw 'Pipeline failed.' }
