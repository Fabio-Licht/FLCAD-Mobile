# Geometry Kernel Adapter

`GeometryKernelAdapter` declara capacidades e executa features, booleanos e validação. Open Cascade, Parasolid e kernel proprietário devem implementar este contrato. O adapter padrão lança `UnsupportedError`; não existe fallback geométrico falso.
