//
//  AppConstants.swift
//  UnivrCore
//
//  Created by Leonardo Rossi on 12/12/25.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import Foundation

public enum AppConstants: Sendable {
    public enum URLs {
        public static let donation = URL(string: "https://revolut.me/leorossi05?currency=EUR&amount=100")!
        public static let portfolio = URL(string: "https://www.leonardorossi.dev")!
        public static let github = URL(string: "https://github.com/leorossi2005")!
        public static let instagram = URL(string: "https://www.instagram.com/leorossi05")!
        public static let feedback = URL(string: "mailto:leonardo.rossi1922005@gmail.com?subject=Feedback%20App%20Univr")!
        public static let email = URL(string: "mailto:leonardo.rossi1922005@gmail.com")!
    }
    
    public enum AppInfo {
        public static let appName = String(localized: "Calendario per UniVR", bundle: .module)
        public static let developerName = "Leonardo Rossi"
    }
    
    public enum Credits {
        public static let contributors: [Contributor] = [
            Contributor(name: "Gaia", role: String(localized: "Aiuto Sviluppo", bundle: .module), image: "GaiaPhoto"),
            Contributor(name: "Nicola", role: String(localized: "Aiuto Testing", bundle: .module), image: "NicolaPhoto"),
            Contributor(name: "Edoardo", role: String(localized: "Aiuto Testing", bundle: .module))
        ]
    }
    
    
    public enum WhatsNewData {
        public static let versions: [WhatsNewVersion] = [
            WhatsNewVersion(
                version: "0.9",
                date: Date(year: 2026, month: 1, day: 6),
                headline: String(localized: "iPad, Offline e un look tutto nuovo", bundle: .module),
                features: [
                    WhatsNewFeature(
                        icon: .system("ipad.landscape"),
                        accentColor: .blue,
                        title: String(localized: "Supporto Nativo per iPad", bundle: .module),
                        shortDescription: String(localized: "Esperienza ottimizzata per schermi grandi con layout adattivi e split view.", bundle: .module),
                        detailedDescription: String(localized: "Univr Calendar ora è completamente ottimizzato per iPad! Goditi un'esperienza fluida con layout adattivi, split view per visualizzare le settimane in landscape e interfaccia pensata appositamente per schermi più grandi. Ogni elemento è stato ripensato per sfruttare al meglio lo spazio disponibile.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("wifi.slash"),
                        accentColor: .orange,
                        title: String(localized: "Modalità Offline", bundle: .module),
                        shortDescription: String(localized: "Consulta le tue lezioni anche senza connessione, sincronizzazione automatica.", bundle: .module),
                        detailedDescription: String(localized: "Niente più preoccupazioni per la connessione! L'app rileva in tempo reale quando sei offline e ti avvisa con un indicatore dedicato, permettendoti di consultare le lezioni salvate. L'onboarding e le impostazioni si bloccano automaticamente senza rete. Appena torni online, tutto si sincronizza in background senza alcun intervento da parte tua.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("sparkles"),
                        accentColor: .purple,
                        title: String(localized: "Interfaccia Rinnovata", bundle: .module),
                        shortDescription: String(localized: "Sheet personalizzate, animazioni fluide ed effetti liquid glass.", bundle: .module),
                        detailedDescription: String(localized: "Le sheet di sistema sono state sostituite da una sheet completamente personalizzata, costruita con UIKit, che offre gesture avanzate, effetti liquid glass dinamici e un controllo totale sulle animazioni. Su iPad il corner radius della sheet si adatta automaticamente alla posizione della finestra. Il risultato? Un'app ancora più bella e piacevole da usare.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("wrench.and.screwdriver"),
                        accentColor: .gray,
                        title: String(localized: "Miglioramenti e Correzioni", bundle: .module),
                        shortDescription: String(localized: "Bug fix, performance migliorate e supporto per iOS 17/18.", bundle: .module),
                        detailedDescription: String(localized: "• Nuovo stile per le lezioni cancellate con bordo e testo barrato\n• Hover effects su iPad per un'interazione più naturale\n• Picker data e ora completamente ridisegnati con performance migliorate\n• Mappa dell'aula ora statica per maggiore stabilità e velocità\n• Risolti numerosi bug con la sheet personalizzata su iOS 17 e 18\n• Supporto ottimizzato per iOS 17, 18 e iPadOS\n• Dettagli lezione ridisegnati con layout migliorato\n• Performance generali notevolmente migliorate", bundle: .module)
                    )
                ]
            ),
            WhatsNewVersion(
                version: "0.8",
                date: Date(year: 2025, month: 12, day: 12),
                headline: String(localized: "Donazioni, nuova ricerca e velocità", bundle: .module),
                features: [
                    WhatsNewFeature(
                        icon: .system("cup.and.saucer"),
                        accentColor: .blue,
                        title: String(localized: "Sezione Donazioni", bundle: .module),
                        shortDescription: String(localized: "Supporta lo sviluppatore con una donazione direttamente dall'app.", bundle: .module),
                        detailedDescription: String(localized: "Nelle impostazioni è stata aggiunta una nuova sezione con un link per effettuare una donazione allo sviluppatore tramite Revolut. Se l'app ti è utile, ora puoi mostrare il tuo apprezzamento con un piccolo contributo. Grazie di cuore!", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("list.bullet.rectangle"),
                        accentColor: .orange,
                        title: String(localized: "Selezione Corso Ridisegnata", bundle: .module),
                        shortDescription: String(localized: "La ricerca del corso è stata ripensata da zero con un nuovo componente.", bundle: .module),
                        detailedDescription: String(localized: "L'interfaccia di selezione del corso è stata completamente riscritta in un componente dedicato condiviso tra onboarding e impostazioni. La barra di ricerca ora ha un pulsante per cancellare il testo, i risultati si caricano in modo più fluido e lo stile è stato uniformato con sfondi adattivi al tema del sistema.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("square.3.layers.3d.bottom.filled"),
                        accentColor: .purple,
                        title: String(localized: "Prestazioni in Background", bundle: .module),
                        shortDescription: String(localized: "L'elaborazione dei dati avviene ora interamente in background.", bundle: .module),
                        detailedDescription: String(localized: "L'organizzazione del calendario, la generazione del date picker e tutte le operazioni di lettura e scrittura della cache vengono ora eseguite in background. I campi delle lezioni come durata, nome pulito e tag sono pre-calcolati al caricamento, rendendo lo scorrimento istantaneo.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("wrench.and.screwdriver"),
                        accentColor: .gray,
                        title: String(localized: "Miglioramenti e Correzioni", bundle: .module),
                        shortDescription: String(localized: "Architettura rinnovata, animazioni fluide e tanti fix.", bundle: .module),
                        detailedDescription: String(localized: "• Navigazione semplificata: ContentView e RootView unite in un'unica vista\n• Aggiornamento a Swift 6.2 con Strict Concurrency per maggiore stabilità\n• Cache convertita in actor per sicurezza tra thread garantita\n• Logica di onboarding e impostazioni unificata in un componente condiviso\n• Crediti nella pagina Info ora interattivi con link al portfolio\n• Placeholder di caricamento migliorato con più elementi e shimmer rinnovato\n• Animazioni più fluide nell'onboarding con transizioni snappy\n• Costanti dell'app centralizzate per una manutenzione più semplice", bundle: .module)
                    )
                ]
            ),
            WhatsNewVersion(
                version: "0.7",
                date: Date(year: 2025, month: 12, day: 4),
                headline: String(localized: "Due lingue, splash screen e crediti", bundle: .module),
                features: [
                    WhatsNewFeature(
                        icon: .system("globe"),
                        accentColor: .blue,
                        title: String(localized: "Italiano e Inglese", bundle: .module),
                        shortDescription: String(localized: "L'app è ora completamente tradotta in italiano e inglese.", bundle: .module),
                        detailedDescription: String(localized: "Ogni testo dell'app è stato tradotto: dall'onboarding alle impostazioni, dai messaggi di errore ai dettagli delle lezioni. La lingua si adatta automaticamente a quella impostata sul dispositivo, così l'esperienza è naturale fin dal primo avvio.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("sparkle"),
                        accentColor: .orange,
                        title: String(localized: "Splash Screen Animato", bundle: .module),
                        shortDescription: String(localized: "L'app si apre con un'animazione che porta l'icona nell'onboarding.", bundle: .module),
                        detailedDescription: String(localized: "All'apertura dell'app viene mostrata una splash screen con l'icona che, al primo avvio, si anima e si sposta fluida nella pagina di benvenuto dell'onboarding grazie a una transizione coordinata. Se hai già completato la configurazione, la splash scompare rapidamente.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("gearshape"),
                        accentColor: .purple,
                        title: String(localized: "Impostazioni Rinnovate", bundle: .module),
                        shortDescription: String(localized: "Nuove icone, sezione Info con versione e crediti, e conferma reset.", bundle: .module),
                        detailedDescription: String(localized: "Le impostazioni hanno un look completamente nuovo con icone per ogni voce e una migliore organizzazione. È stata aggiunta la sezione Info con la versione dell'app, i crediti e i contributori. La ricerca dei corsi ora ha una lista scorrevole con pulsante di chiusura e il reset dell'app richiede una conferma per evitare errori.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("wrench.and.screwdriver"),
                        accentColor: .gray,
                        title: String(localized: "Miglioramenti e Correzioni", bundle: .module),
                        shortDescription: String(localized: "Pause ridisegnate, lezioni annullate e preparazione TestFlight.", bundle: .module),
                        detailedDescription: String(localized: "• Le pause tra le lezioni mostrano ora un'icona tazza al posto del testo semplice\n• Le lezioni con sfondo bianco su tema chiaro hanno ora un bordo visibile\n• Le lezioni annullate appaiono ora con opacità ridotta per distinguerle meglio\n• Separata l'architettura dell'app in modulo Apple e modulo multipiattaforma\n• Preparata l'app per la distribuzione su TestFlight con privacy manifest e nuovo Bundle ID\n• Corretti bug nel reset dell'app e nella riapertura della sheet", bundle: .module)
                    )
                ]
            ),
            WhatsNewVersion(
                version: "0.6",
                date: Date(year: 2025, month: 12, day: 2),
                headline: String(localized: "Lezioni più leggibili e nuova icona", bundle: .module),
                features: [
                    WhatsNewFeature(
                        icon: .system("textformat.abc"),
                        accentColor: .blue,
                        title: String(localized: "Nomi Lezioni Semplificati", bundle: .module),
                        shortDescription: String(localized: "I nomi dei corsi vengono abbreviati automaticamente e mostrano tag utili.", bundle: .module),
                        detailedDescription: String(localized: "I nomi delle lezioni vengono ora formattati in modo intelligente: parole come \"Laboratorio\" o \"Teoria\" diventano tag colorati sotto il nome, le parentesi e le informazioni tecniche vengono estratte e semplificate. Il risultato è un nome più corto e leggibile a colpo d'occhio.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("sparkles.rectangle.stack"),
                        accentColor: .orange,
                        title: String(localized: "Card Lezione Ridisegnata", bundle: .module),
                        shortDescription: String(localized: "Nuovo layout con orario a sinistra, dettagli a destra e tag colorati.", bundle: .module),
                        detailedDescription: String(localized: "La scheda di ogni lezione ha un aspetto completamente nuovo: l'orario di inizio e la durata sono a sinistra, il nome del corso, l'aula e i tag a destra. Il gradiente è stato sostituito da un colore pieno proveniente dall'università, per un look più pulito e coerente.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .asset("AppIconV0.6"),
                        accentColor: .purple,
                        title: String(localized: "Prima Icona dell'App", bundle: .module),
                        shortDescription: String(localized: "Univr Calendar ha finalmente la sua icona personalizzata.", bundle: .module),
                        detailedDescription: String(localized: "L'app ha ora un'icona dedicata con un design che richiama il calendario e la lente d'ingrandimento, pensata per essere riconoscibile fin dalla schermata principale del dispositivo.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("wrench.and.screwdriver"),
                        accentColor: .gray,
                        title: String(localized: "Miglioramenti e Correzioni", bundle: .module),
                        shortDescription: String(localized: "Calendario localizzato, dettagli migliorati e vari fix.", bundle: .module),
                        detailedDescription: String(localized: "• Il calendario ora rispetta la lingua impostata sul dispositivo dell'utente\n• I simboli del giorno e del mese sono ora capitalizzati correttamente\n• Migliorato il layout della schermata dettagli lezione con data, orario, docente e capienza\n• Corretti problemi con la cache degli anni accademici\n• Risolti bug nell'aggiornamento delle date del calendario\n• Impedito di navigare verso giorni non disponibili nel calendario", bundle: .module)
                    )
                ]
            ),
            WhatsNewVersion(
                version: "0.5",
                date: Date(year: 2025, month: 11, day: 27),
                headline: String(localized: "Dettagli lezione e velocità al top", bundle: .module),
                features: [
                    WhatsNewFeature(
                        icon: .system("info.circle"),
                        accentColor: .blue,
                        title: String(localized: "Dettagli della Lezione", bundle: .module),
                        shortDescription: String(localized: "Tocca una lezione per vedere tutte le informazioni e la mappa dell'aula.", bundle: .module),
                        detailedDescription: String(localized: "Ora puoi toccare qualsiasi lezione per aprire una schermata dettagliata con orario, docente, aula e una mappa interattiva che mostra la posizione approssimativa dell'edificio. Puoi anche toccare il titolo per vedere il nome completo del corso.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("chart.line.uptrend.xyaxis"),
                        accentColor: .orange,
                        title: String(localized: "Performance Migliorate", bundle: .module),
                        shortDescription: String(localized: "Caricamento più veloce del \(0.4, format: .percent) e transizioni fluide nella sheet.", bundle: .module),
                        detailedDescription: String(localized: "L'organizzazione dei dati è stata ottimizzata con un miglioramento di circa il \(0.4, format: .percent) nei tempi di elaborazione. Molti valori vengono ora pre-calcolati al primo caricamento, così le schermate si aprono istantaneamente. Anche la sheet in basso ha nuove animazioni di opacità dinamiche che rendono le transizioni più naturali.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("cylinder.split.1x2"),
                        accentColor: .purple,
                        title: String(localized: "Cache di Rete", bundle: .module),
                        shortDescription: String(localized: "I dati scaricati vengono salvati e aggiornati in automatico.", bundle: .module),
                        detailedDescription: String(localized: "Le informazioni su anni, corsi e anni accademici vengono ora salvate localmente dopo il primo download. Alle aperture successive l'app li carica dalla cache e verifica in background se ci sono aggiornamenti, rendendo la navigazione molto più rapida.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("wrench.and.screwdriver"),
                        accentColor: .gray,
                        title: String(localized: "Miglioramenti e Correzioni", bundle: .module),
                        shortDescription: String(localized: "Calendario più fluido, colori ottimizzati e tanti bug fix.", bundle: .module),
                        detailedDescription: String(localized: "• Risolto definitivamente il bug che all'apertura non selezionava il giorno corretto\n• Ottimizzata la conversione dei colori con un sistema di cache dedicato\n• Migliorata l'estrazione JSON con regex più performanti\n• Il calendario non si muove più in modo irregolare durante lo scroll\n• Date picker e calendario compatto ora usano cache interna per rigenerarsi senza ricalcolare tutto", bundle: .module)
                    )
                ]
            ),
            WhatsNewVersion(
                version: "0.4",
                date: Date(year: 2025, month: 11, day: 23),
                headline: String(localized: "Avvio più veloce e design adattivo", bundle: .module),
                features: [
                    WhatsNewFeature(
                        icon: .system("hare"),
                        accentColor: .blue,
                        title: String(localized: "Avvio Rapido con la Cache", bundle: .module),
                        shortDescription: String(localized: "L'app carica i dati salvati e controlla aggiornamenti in automatico.", bundle: .module),
                        detailedDescription: String(localized: "Ora all'apertura l'app carica istantaneamente le lezioni salvate in precedenza, senza attendere la rete. In background viene verificata la disponibilità di aggiornamenti: se ci sono novità, un avviso ti permette di aggiornare i dati quando preferisci.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("network.badge.shield.half.filled"),
                        accentColor: .orange,
                        title: String(localized: "Rete Più Affidabile", bundle: .module),
                        shortDescription: String(localized: "Messaggi di errore chiari e una connessione più stabile.", bundle: .module),
                        detailedDescription: String(localized: "Il sistema di rete è stato riscritto con un metodo più affidabile per estrarre i dati dal server. I messaggi di errore sono ora specifici e in italiano, così puoi capire subito cosa è andato storto senza dover interpretare codici tecnici.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("paintbrush.pointed"),
                        accentColor: .purple,
                        title: String(localized: "Interfaccia su Misura", bundle: .module),
                        shortDescription: String(localized: "Le finestre seguono la curvatura reale del tuo dispositivo.", bundle: .module),
                        detailedDescription: String(localized: "Il raggio degli angoli delle finestre sovrapposte ora si adatta automaticamente al modello del tuo iPhone o iPad, per un aspetto più armonioso e naturale. Anche i numeri e i nomi dei giorni nel calendario sono stati uniformati per una lettura più chiara.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("wrench.and.screwdriver"),
                        accentColor: .gray,
                        title: String(localized: "Miglioramenti e Correzioni", bundle: .module),
                        shortDescription: String(localized: "Impostazioni centralizzate, date migliorate e vari fix.", bundle: .module),
                        detailedDescription: String(localized: "• Le impostazioni dell'app sono state centralizzate in un unico punto, più affidabili e condivise ovunque\n• Corretta la selezione del giorno all'apertura dell'app che non sempre andava al giorno giusto\n• Migliorato il calendario con stati disabilitati più chiari e interazioni più precise\n• Aggiunto un messaggio dedicato quando non vengono trovate lezioni per il corso selezionato\n• Numerosi bug fix nella navigazione e nella gestione delle date", bundle: .module)
                    )
                ]
            ),
            WhatsNewVersion(
                version: "0.3",
                date: Date(year: 2025, month: 11, day: 20),
                headline: String(localized: "Nuovo benvenuto e compatibilità iOS", bundle: .module),
                features: [
                    WhatsNewFeature(
                        icon: .system("rectangle.portrait.on.rectangle.portrait.angled"),
                        accentColor: .blue,
                        title: String(localized: "Pagina di Benvenuto", bundle: .module),
                        shortDescription: String(localized: "Una nuova schermata introduttiva apre l'onboarding.", bundle: .module),
                        detailedDescription: String(localized: "L'onboarding ora inizia con una pagina di benvenuto che presenta l'app e il suo scopo. Un modo più accogliente per guidarti nella configurazione iniziale, con la possibilità in futuro di includere un'animazione dedicata.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("hand.draw"),
                        accentColor: .orange,
                        title: String(localized: "Scorri le Settimane", bundle: .module),
                        shortDescription: String(localized: "Cambia settimana con uno swipe dal calendario compatto.", bundle: .module),
                        detailedDescription: String(localized: "Nel calendario compatto in basso puoi ora scorrere a sinistra o a destra per passare alla settimana precedente o successiva. Il primo giorno della nuova settimana viene selezionato automaticamente.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("square.stack.3d.up"),
                        accentColor: .purple,
                        title: String(localized: "Architettura MVVM", bundle: .module),
                        shortDescription: String(localized: "Logica e interfaccia ora sono completamente separate.", bundle: .module),
                        detailedDescription: String(localized: "L'app è stata ristrutturata con il pattern MVVM: la logica di caricamento lezioni, organizzazione dati e rete è ora gestita da ViewModel dedicati per il calendario, l'onboarding e le impostazioni.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("iphone.gen2"),
                        accentColor: .green,
                        title: String(localized: "Supporto iOS 17 e 18", bundle: .module),
                        shortDescription: String(localized: "Compatibilità estesa alle versioni precedenti di iOS.", bundle: .module),
                        detailedDescription: String(localized: "L'app è ora retrocompatibile con iOS 17 e 18 grazie a fallback dedicati per i componenti più recenti. Stili dei pulsanti, effetti visivi e layout si adattano automaticamente alla versione del sistema.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("wrench.and.screwdriver"),
                        accentColor: .gray,
                        title: String(localized: "Miglioramenti e Correzioni", bundle: .module),
                        shortDescription: String(localized: "Rete migliorata, file riorganizzati e vari fix.", bundle: .module),
                        detailedDescription: String(localized: "• Migliorato il parsing JSON delle risposte di rete per una maggiore affidabilità\n• Riorganizzati tutti i file in cartelle dedicate (App, Core, UI)\n• Le viste sono state separate in file distinti per una gestione più semplice\n• Le estensioni sono state divise tra logica e UI per facilitare future migrazioni\n• Corretti numerosi bug nella navigazione e nel caricamento", bundle: .module)
                    )
                ]
            ),
            WhatsNewVersion(
                version: "0.2",
                date: Date(year: 2025, month: 11, day: 19),
                headline: String(localized: "Scorri i giorni e nuovo calendario", bundle: .module),
                features: [
                    WhatsNewFeature(
                        icon: .system("hand.draw"),
                        accentColor: .blue,
                        title: String(localized: "Scorri tra i Giorni", bundle: .module),
                        shortDescription: String(localized: "Passa da un giorno all'altro con uno swipe orizzontale.", bundle: .module),
                        detailedDescription: String(localized: "Ora puoi navigare tra i giorni direttamente dalla schermata principale con uno swipe a destra o sinistra. Ogni giorno mostra le sue lezioni, le pause e un messaggio se non ci sono lezioni. Tutto l'anno accademico è già pronto per essere sfogliato.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("calendar"),
                        accentColor: .red,
                        title: String(localized: "Calendario Personalizzato", bundle: .module),
                        shortDescription: String(localized: "Un nuovo calendario mensile sostituisce quello di sistema.", bundle: .module),
                        detailedDescription: String(localized: "Il calendario di sistema è stato sostituito con uno personalizzato, pensato per adattarsi meglio all'app. Puoi navigare tra i mesi e selezionare qualsiasi giorno in modo più rapido e intuitivo.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("network.badge.shield.half.filled"),
                        accentColor: .orange,
                        title: String(localized: "Rete più Moderna", bundle: .module),
                        shortDescription: String(localized: "Le chiamate di rete ora usano async/await per una maggiore affidabilità.", bundle: .module),
                        detailedDescription: String(localized: "Tutte le funzioni di rete sono state riscritte con async/await e Task, sostituendo il vecchio sistema a callback. Il risultato è un caricamento più stabile e reattivo, con una gestione degli errori più chiara.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("wrench.and.screwdriver"),
                        accentColor: .gray,
                        title: String(localized: "Miglioramenti e Correzioni", bundle: .module),
                        shortDescription: String(localized: "Riorganizzazione interna e vari bug risolti.", bundle: .module),
                        detailedDescription: String(localized: "• Aggiunte numerose utility per lavorare con le date in modo più semplice\n• Rimosso SwiftData dal progetto, non più necessario\n• Rinominato il file dei modelli per una struttura più chiara\n• Aggiunto un identificativo univoco alle lezioni\n• Corretti diversi bug nella navigazione e nel calendario", bundle: .module)
                    )
                ]
            ),
            WhatsNewVersion(
                version: "0.1",
                date: Date(year: 2025, month: 10, day: 20),
                headline: String(localized: "Nasce l'app, tutto parte da qui", bundle: .module),
                features: [
                    WhatsNewFeature(
                        icon: .system("app.badge.checkmark"),
                        accentColor: .blue,
                        title: String(localized: "Nasce Univr Calendar", bundle: .module),
                        shortDescription: String(localized: "Visualizza le tue lezioni del giorno, scegli il corso e inizia subito.", bundle: .module),
                        detailedDescription: String(localized: "Univr Calendar nasce con tutto il necessario per partire: una schermata principale che mostra le lezioni del giorno, un onboarding guidato per scegliere anno accademico e corso di laurea, e le impostazioni per cambiare le tue preferenze in qualsiasi momento.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("calendar"),
                        accentColor: .green,
                        title: String(localized: "Pulsante Calendario", bundle: .module),
                        shortDescription: String(localized: "Si apre e chiude in automatico mentre scorri le lezioni.", bundle: .module),
                        detailedDescription: String(localized: "Il nuovo pulsante Calendario nella barra in basso si comporta in modo intelligente: si apre quando torni in cima alla lista, si chiude quando scorri verso il basso e si riapre quando passi al giorno successivo. Così hai sempre le informazioni giuste al momento giusto.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("magnifyingglass"),
                        accentColor: .teal,
                        title: String(localized: "Ricerca Corsi", bundle: .module),
                        shortDescription: String(localized: "Trova il tuo corso in un attimo con la barra di ricerca.", bundle: .module),
                        detailedDescription: String(localized: "Non devi più scorrere l'intera lista: basta digitare il nome del corso e la lista si filtra istantaneamente. Disponibile sia durante la configurazione iniziale sia nelle impostazioni.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("person.text.rectangle"),
                        accentColor: .purple,
                        title: String(localized: "Matricola Intelligente", bundle: .module),
                        shortDescription: String(localized: "La scelta pari/dispari appare solo quando il corso lo richiede.", bundle: .module),
                        detailedDescription: String(localized: "L'app rileva automaticamente se il tuo corso prevede la distinzione tra matricole pari e dispari. Se non serve, la pagina viene saltata nell'onboarding e nascosta nelle impostazioni, rendendo tutto più semplice e veloce.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("bolt.fill"),
                        accentColor: .orange,
                        title: String(localized: "Caricamenti Più Veloci", bundle: .module),
                        shortDescription: String(localized: "I dati vengono caricati una sola volta e riutilizzati ovunque.", bundle: .module),
                        detailedDescription: String(localized: "Anni, corsi e anni accademici vengono scaricati una volta e condivisi tra tutte le schermate. Le impostazioni non ricaricano più i dati se sono già disponibili, rendendo la navigazione più fluida e riducendo i tempi di attesa.", bundle: .module)
                    ),
                    WhatsNewFeature(
                        icon: .system("wrench.and.screwdriver"),
                        accentColor: .gray,
                        title: String(localized: "Miglioramenti e Correzioni", bundle: .module),
                        shortDescription: String(localized: "Vari bug risolti e miglioramenti di stabilità.", bundle: .module),
                        detailedDescription: String(localized: "• Corretto un problema che impediva di visualizzare le lezioni degli anni precedenti\n• Risolto un errore nel filtro che nascondeva alcune lezioni per corsi senza distinzione matricola\n• Migliorato il supporto al tema chiaro nell'indicatore di caricamento\n• Migliorata la compatibilità con diverse dimensioni di schermo", bundle: .module)
                    )
                ]
            )
        ]
    }
}
