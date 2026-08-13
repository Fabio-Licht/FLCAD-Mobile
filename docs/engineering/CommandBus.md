# Engineering Command and Query Buses

Commands mutate state and carry audit data; results may provide undo. Query handlers are separate and read-only. Command executions publish audit events. FEL is an input adapter and should translate parsed commands to EngineeringCommand objects as handlers migrate.
