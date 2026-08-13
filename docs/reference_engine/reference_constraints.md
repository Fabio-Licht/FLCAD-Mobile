# Reference Constraints

`ReferenceConstraint` armazena tipo, referências participantes, parâmetros e estado. `ReferenceConstraintValidator` valida paralelo, perpendicular, coincidente, concêntrico, distância e ângulo fixos com tolerância configurável.

Tangência exige uma representação de superfície e retorna explicitamente `requires a surface adapter`; ela não é simulada no Alpha. O validador não altera geometria, o que permite reutilização futura por Sketch e CAD. Um solver poderá consumir os mesmos modelos sem mudança no formato persistido.
