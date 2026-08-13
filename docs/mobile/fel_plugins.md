# FEL Plugins and Distributed Execution

Plugins register `FELCommand` implementations through `FELPluginManager`; parser/runtime remain unchanged. Unloading removes only the plugin's commands. Plugins receive `FELExecutionContext` and must obey Project First and Smart Regions-only mesh interaction.

`NaturalLanguageFELAdapter` translates intent to source but never executes it. `RemoteFELExecutor` transports source and cancellation identifiers for Cloud. Security, signing and sandbox policy are required before accepting third-party scripts or plugins in production.
