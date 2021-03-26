---
layout: page_with_toc
title: Kommunikation mit dem Server
subtitle: Die Dateien in diesem Paket dienen dazu mit EEP-Web zu kommunizieren.
permalink: lua/ak/io/
feature-img: "/docs/assets/headers/SourceCode.png"
img: "/docs/assets/headers/SourceCode.png"
---

# Motivation

Dieses Paket kommuniziert über Dateien (schreiben und lesen) mit dem Server, der die Daten von EEP-Web anzeigt.

## Dateien

`ak-eep-out.log`
EEP appends the log to this file.

`ak-eep-out.json`
EEP writes it's status to this file regularly but only if the Web Server is listening and has finished reading the previous version of the file.

`ak-server.iswatching`
The Web Server creates this file at start and deletes it on exit.
Conclusion: The server is listening while this file exists.

`ak-eep-out-json.isfinished`
EEP creates this empty file after updating the json file to indicate that the Web Servercan now read the json file.
The Web Server should delete this file after reading the json file.
Conclusion: The server is busy while this file exists.
Delete the file during initialization to trigger the creation of the json file once.

`ak-eep-in.commands`
EEP reads commands from this file.