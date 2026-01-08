# UniCalendar

**UniCalendar** è un'applicazione iOS nativa (SwiftUI + UIKit) progettata per semplificare la vita degli studenti dell'Università di Verona (UniVR). Offre un'interfaccia moderna, fluida e reattiva per consultare gli orari delle lezioni, aiutando gli studenti a organizzarsi meglio e liberare la mente per lo studio.

> 🚧 **Stato del progetto**: In sviluppo attivo (v0.9)

## ✨ Funzionalità Principali

### 📅 Gestione Orari Avanzata
*   **Visualizzazione Settimanale Fluid**: Navigazione intuitiva tra le settimane con supporto allo scrolling frazionato.
*   **Custom Sheet Interattivo**: Un pannello inferiore personalizzato (basato su UIKit) con supporto a detent multipli (medium/large) e transizioni "liquid glass" fluide.
*   **Dettagli Lezione Completi**: Visualizza orario, aula e posizione approssimativa sulla mappa integrata.
*   **Supporto Offline**: Rileva automaticamente lo stato della connessione e permette la consultazione della cache locale quando sei offline.

### 🎨 Design e UX
*   **Interfaccia Adattiva**: Ottimizzata sia per iPhone che per iPad (con supporto SplitView e rotazione).
*   **Animazioni Curate**: Transizioni "snappy", effetti glass/blur dinamici e animazioni personalizzate per l'apertura del calendario.
*   **Localizzazione**: Completamente tradotta in **Italiano** e **Inglese**.
*   **Modalità Scura**: Supporto nativo per il tema scuro con adattamento automatico dei colori.

### ⚙️ Aspetti Tecnici
*   **Architettura Ibrida**: Core condiviso multi-piattaforma (predisposto per Android) e UI nativa Apple.
*   **Caching Intelligente**: Sistema di caching avanzato per ridurre i tempi di caricamento (da ~500ms a <50ms) e risparmiare dati.
*   **Network Resiliente**: Gestione robusta delle chiamate API con background refresh.

## 🛠 Requisiti
*   **iOS**: 17.0+
*   **Xcode**: 26.0+ (Testato su 26.2)
*   **Linguaggio**: Swift 5.9+

## 🚀 Installazione

1.  **Clona il repository**:
    ```bash
    git clone https://github.com/leorossi2005/UniCalendar.git
    ```
2.  **Apri il progetto**:
    Fai doppio clic su `Univr Calendar.xcodeproj` nella cartella scaricata.
3.  **Attendi i pacchetti**:
    Lascia che Xcode risolva le dipendenze tramite Swift Package Manager.
4.  **Esegui**:
    Seleziona un simulatore (es. iPhone 15 Pro) e premi `Cmd + R` per avviare l'app.

## 🧩 Struttura del Progetto

Il progetto è diviso in due moduli principali per favorire la portabilità e l'ordine:

*   **Univr App** (Codice specifico Apple):
    *   `App/`: File base dell'app.
    *   `UI/Components/`: Componenti SwiftUI indipendenti.
    *   `UI/Helpers/`: Componenti UIKit che assistono SwiftUI.
    *   `UI/UIKit/`: View e componenti UIKit.
    *   `UI/Views/`: View SwiftUI principali dell'app.
*   **Univr Core** (Logica condivisa):
    *   `ViewModels/`: Codice computazionale per le view.
    *   `/`: File generali del package.

## 📄 Licenza

Questo progetto è distribuito sotto licenza **GNU GPLv3**.
Vedi il file [LICENSE](LICENSE) per maggiori dettagli.

Software libero: puoi usarlo, studiarlo e modificarlo, ma le derivazioni devono rimanere open source.
