# Dependency Injection

`EngineeringServiceRegistry` is the single lightweight container. It supports singleton instances, lazy factories, duplicate protection and explicit replacement. Registration occurs in bootstrap; UI and domains resolve contracts from an `EngineeringContext` rather than constructing peer engines.
