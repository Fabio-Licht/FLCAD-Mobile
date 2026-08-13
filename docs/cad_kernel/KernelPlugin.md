# OpenCascade Kernel Plugin

`OpenCascadeKernelPlugin` registers the official adapter in `KernelManager`. Registration does not imply availability: selection performs native initialization, version verification, diagnostics and health checking.

The plugin ID is `opencascade-plugin`; the kernel ID remains `opencascade`. All vendor dependencies must stay below `OpenCascadeNativeBridge`.

