# Engineering Services

`EngineeringServiceRegistry` registers engines and adapters by type. `EngineeringKernel`, Learning, Knowledge providers, logger sinks and metrics are services resolved from EngineeringContext. Registration belongs in the application composition root; domain models never use global service locators.
