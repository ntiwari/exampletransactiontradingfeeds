-- AUDIT TRAIL

CREATE TABLE audit_trail (
    audit_id SERIAL PRIMARY KEY,
    user_id INT,
    event_type VARCHAR(50),
    entity_affected VARCHAR(100),
    action_taken TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW v_user_activity AS
SELECT
    user_id,
    event_type,
    entity_affected,
    action_taken,
    timestamp
FROM audit_trail
ORDER BY timestamp DESC;

CREATE OR REPLACE PROCEDURE sp_log_event (
    IN _user_id INT,
    IN _event_type VARCHAR,
    IN _entity_affected VARCHAR,
    IN _action_taken TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO audit_trail (user_id, event_type, entity_affected, action_taken)
    VALUES (_user_id, _event_type, _entity_affected, _action_taken);
END;
$$;