INSTALL sqlite;
LOAD sqlite;
SET sqlite_all_varchar=true;

ATTACH 'C:\Users\Pichau\OneDrive\Documentos\Estudos Dudu\7. atraso-voos\data\database.db' AS database (TYPE SQLITE);
ATTACH 'C:\Users\Pichau\OneDrive\Documentos\Estudos Dudu\7. atraso-voos\data\features.duckdb' AS local_duck