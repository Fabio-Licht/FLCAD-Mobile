# Transition Architecture

One shared engine owns Sweep and Loft preparation, execution state, graphs, history, analytics and persistence. Builders provide family-specific entry points without duplicating the execution pipeline.
