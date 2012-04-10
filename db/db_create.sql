PRAGMA foreign_keys = ON;

DROP INDEX IF EXISTS rrm1;
DROP INDEX IF EXISTS prm1;
DROP INDEX IF EXISTS pm1;

DROP TRIGGER IF EXISTS result_metadata_modified;
DROP TRIGGER IF EXISTS result_modified;
DROP TRIGGER IF EXISTS run_metadata_modified;
DROP TRIGGER IF EXISTS run_modified;
DROP TRIGGER IF EXISTS project_metadata_modified;
DROP TRIGGER IF EXISTS project_modified;

DROP TABLE IF EXISTS result_metadata;
DROP TABLE IF EXISTS result;
DROP TABLE IF EXISTS run_metadata;
DROP TABLE IF EXISTS run;
DROP TABLE IF EXISTS project_metadata;
DROP TABLE IF EXISTS project;

CREATE TABLE project (
  id INTEGER NOT NULL,
  name TEXT NOT NULL,
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  modified TIMESTAMP,
  PRIMARY KEY ( id ),
  UNIQUE ( name )
);

CREATE TABLE project_metadata (
  id INTEGER NOT NULL,
  project_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  value TEXT NOT NULL,
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  modified TIMESTAMP,
  PRIMARY KEY ( id ),
  FOREIGN KEY ( project_id ) REFERENCES project ( id ) ON DELETE CASCADE
);

CREATE TABLE run (
  id INTEGER NOT NULL,
  project_id INTEGER NOT NULL,
  description TEXT NOT NULL,
  submitted_by TEXT NOT NULL,
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  modified TIMESTAMP,
  PRIMARY KEY ( id ),
  FOREIGN KEY ( project_id ) REFERENCES project ( id ) ON DELETE CASCADE
); 

CREATE TABLE run_metadata (
  id INTEGER NOT NULL,
  run_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  value TEXT NOT NULL,
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  modified TIMESTAMP,
  PRIMARY KEY ( id ),
  FOREIGN KEY ( run_id ) REFERENCES run ( id ) ON DELETE CASCADE
);


CREATE TABLE result (
  id INTEGER NOT NULL,
  run_id INTEGER NOT NULL,
  test_case TEXT NOT NULL,
  status TEXT NOT NULL,
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  modified TIMESTAMP,
  PRIMARY KEY ( id ),
  FOREIGN KEY ( run_id ) REFERENCES run ( id ) ON DELETE CASCADE
);

CREATE TABLE result_metadata (
  id INTEGER NOT NULL,
  result_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  value TEXT NOT NULL,
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  modified TIMESTAMP,
  PRIMARY KEY ( id ),
  FOREIGN KEY ( result_id ) REFERENCES result ( id ) ON DELETE CASCADE
);

CREATE UNIQUE INDEX pm1  ON project_metadata ( project_id, name );
CREATE UNIQUE INDEX prm1 ON run_metadata     ( run_id,     name );
CREATE UNIQUE INDEX rrm1 ON result_metadata  ( result_id,  name );

CREATE TRIGGER project_modified AFTER UPDATE ON project
  BEGIN
    UPDATE project
    SET modified = CURRENT_TIMESTAMP
    WHERE id = new.id;
  END;

CREATE TRIGGER project_metadata_modified AFTER UPDATE ON project_metadata
  BEGIN
    UPDATE project_metadata
    SET modified = CURRENT_TIMESTAMP
    WHERE id = new.id;
  END;

CREATE TRIGGER run_modified AFTER UPDATE ON run
  BEGIN
    UPDATE run
    SET modified = CURRENT_TIMESTAMP
    WHERE id = new.id;
  END;

CREATE TRIGGER run_metadata_modified AFTER UPDATE ON run_metadata
  BEGIN
    UPDATE run_metadata
    SET modified = CURRENT_TIMESTAMP
    WHERE id = new.id;
  END;

CREATE TRIGGER result_modified AFTER UPDATE ON result
  BEGIN
    UPDATE result
    SET modified = CURRENT_TIMESTAMP
    WHERE id = new.id;
  END;

CREATE TRIGGER result_metadata_modified AFTER UPDATE ON result_metadata
  BEGIN
    UPDATE result_metadata
    SET modified = CURRENT_TIMESTAMP
    WHERE id = new.id;
  END;

