# FLCAD PLATFORM

# FLSCAN File Format

Versão: 1.0

Documento Oficial

Status: Em Desenvolvimento

Documento: 06_FLSCAN.md

---

# Objetivo

Este documento define o formato oficial de armazenamento da plataforma FLCAD.

O formato **.flscan** será utilizado para armazenar todas as informações necessárias para reconstrução, documentação e colaboração.

O objetivo é preservar todo o conhecimento adquirido durante uma digitalização.

---

# Filosofia

Um projeto não é apenas uma coleção de fotografias.

Um projeto representa conhecimento.

O formato FLSCAN deverá preservar esse conhecimento integralmente.

---

# Objetivos

O formato deverá permitir:

- salvar projetos completos;
- interromper uma captura;
- continuar dias depois;
- compartilhar projetos;
- sincronizar entre dispositivos;
- integrar Mobile e Reverse AI.

---

# Estrutura Geral

```text
Projeto.flscan

│

├── project.json

├── sessions/

├── photos/

├── videos/

├── audio/

├── measurements/

├── annotations/

├── preview/

├── reconstruction/

├── ai/

├── metadata/

└── version.json
```

---

# Project

Contém informações gerais.

Exemplo:

- nome;
- cliente;
- descrição;
- responsável;
- data de criação;
- versão.

---

# Sessions

Cada sessão representa uma etapa de captura.

Uma sessão poderá conter:

- fotografias;
- vídeos;
- medições;
- observações;
- metadados.

---

# Photos

Armazena:

- imagem original;
- miniatura;
- EXIF;
- posição;
- orientação;
- qualidade.

---

# Videos

Armazena:

- vídeos;
- metadados;
- miniaturas.

---

# Audio

Armazena:

- gravações;
- transcrições futuras;
- observações.

---

# Measurements

Cada medição deverá armazenar:

- tipo;
- valor;
- unidade;
- precisão;
- origem.

---

# Annotations

Comentários do usuário.

Exemplo:

"Trinca nesta região."

"Superfície desgastada."

---

# Preview

Visualizações rápidas.

Planejamento:

- imagem;
- GLB;
- STL simplificado.

---

# Reconstruction

Resultados gerados.

Exemplos:

- STL;
- OBJ;
- PLY;
- nuvem de pontos.

---

# AI

Toda informação produzida pela IA.

Exemplos:

- cobertura;
- regiões;
- confiança;
- recomendações.

---

# Metadata

Informações técnicas.

Exemplos:

- dispositivo;
- versão do aplicativo;
- sensores utilizados;
- idioma;
- data.

---

# Version

Controle de compatibilidade.

Exemplo:

```json
{
    "format": 1,
    "mobile": "0.4",
    "reverseAI": "0.2"
}
```

---

# Compressão

O formato deverá utilizar compactação.

Objetivos:

- reduzir tamanho;
- acelerar compartilhamento;
- facilitar sincronização.

---

# Compatibilidade

O formato deverá ser compatível entre:

- Android;
- iOS;
- Windows;
- Linux;
- macOS.

---

# Integração

O formato será o elo oficial entre:

Mobile

↓

Cloud

↓

Reverse AI

---

# Segurança

Planejamento futuro:

- assinatura digital;
- criptografia;
- controle de integridade.

---

# Expansibilidade

Novas versões poderão adicionar diretórios sem quebrar compatibilidade.

Exemplo:

```text
thermal/

lidar/

inspection/

reports/
```

---

# Benefícios

- um único arquivo;
- fácil compartilhamento;
- continuidade do trabalho;
- histórico completo;
- integração da plataforma.

---

# Casos de Uso

## Captura

Mobile

↓

FLSCAN

↓

Salvar

---

## Engenharia Reversa

FLSCAN

↓

Reverse AI

↓

CAD

---

## Colaboração

FLSCAN

↓

Cloud

↓

Equipe

---

# Objetivo Final

Transformar o formato FLSCAN no padrão oficial da plataforma FLCAD para armazenamento, transporte e compartilhamento de informações de engenharia.

---

# Visão de Longo Prazo

O formato FLSCAN deverá evoluir para representar um verdadeiro Gêmeo Digital.

Ele não armazenará apenas arquivos.

Ele armazenará contexto, conhecimento, histórico, medições, inteligência artificial e toda a evolução do projeto ao longo do tempo.

---

Fim do Documento