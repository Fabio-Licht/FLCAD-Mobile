# Engineering Event Bus

Strong event envelope: ID, project, domain, type, entity, timestamp, payload, priority and correlation ID. The bus supports sync/async subscribers, filtering, priority ordering, replay query and cancellable subscriptions.

Legacy domain buses are supported during migration. New domain-to-domain communication must publish an EngineeringEvent instead of importing another engine.
