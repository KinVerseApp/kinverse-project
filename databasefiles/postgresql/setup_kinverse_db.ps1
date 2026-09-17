param(
    [string]$Host = "DoubleA-PC",
    [int]$Port = 5432,
    [string]$User = "postgres",
    [string]$Password = "xxxxxxx",
    [string]$Database = "kinverse",
    [switch]$Reset
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$schemaFile = Join-Path $scriptDir "001_kinverse_schema.sql"
$seedFile = Join-Path $scriptDir "002_seed_sample.sql"

if (-not (Test-Path $schemaFile)) { throw "Schema file not found: $schemaFile" }
if (-not (Test-Path $seedFile)) { throw "Seed file not found: $seedFile" }

$env:PGPASSWORD = $Password

if ($Reset) {
    Write-Host "Dropping existing database '$Database' on $Host:$Port..."
    & psql "host=$Host port=$Port dbname=postgres user=$User connect_timeout=10 sslmode=prefer" -c "DROP DATABASE IF EXISTS $Database;"
}

Write-Host "Ensuring database '$Database' exists..."
& psql "host=$Host port=$Port dbname=postgres user=$User connect_timeout=10 sslmode=prefer" -c "SELECT 'CREATE DATABASE $Database' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$Database')\gexec"

Write-Host "Applying schema..."
& psql "host=$Host port=$Port dbname=$Database user=$User connect_timeout=10 sslmode=prefer" -f $schemaFile

Write-Host "Loading sample data..."
& psql "host=$Host port=$Port dbname=$Database user=$User connect_timeout=10 sslmode=prefer" -f $seedFile

Write-Host "KinVerse database setup completed successfully."
Write-Host "Connection string: host=$Host port=$Port dbname=$Database user=$User password=xxxxxxx connect_timeout=10 sslmode=prefer"
