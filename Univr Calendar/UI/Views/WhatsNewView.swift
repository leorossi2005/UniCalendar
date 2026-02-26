//
//  WhatsNewView.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 17/01/26.
//

import SwiftUI

// MARK: - Models

struct WhatsNewFeature: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let shortDescription: String
    let detailedDescription: String?
    
    init(icon: String, iconColor: Color, title: String, shortDescription: String, detailedDescription: String? = nil) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.shortDescription = shortDescription
        self.detailedDescription = detailedDescription
    }
    
    var hasDetails: Bool {
        detailedDescription != nil && !detailedDescription!.isEmpty
    }
}

struct WhatsNewVersion: Identifiable {
    let id = UUID()
    let version: String
    let date: Date
    let headline: String?
    let features: [WhatsNewFeature]
    
    init(version: String, date: String, headline: String? = nil, features: [WhatsNewFeature]) {
        self.version = version
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.date = formatter.date(from: date) ?? Date()
        self.headline = headline
        self.features = features
    }
}

// MARK: - Version History

enum WhatsNewData {
    static let versions: [WhatsNewVersion] = [
        WhatsNewVersion(
            version: "0.9",
            date: "2026-01-06",
            headline: "iPad, Offline e un look tutto nuovo",
            features: [
                WhatsNewFeature(
                    icon: "ipad.landscape",
                    iconColor: .blue,
                    title: "Supporto Nativo per iPad",
                    shortDescription: "Esperienza ottimizzata per schermi grandi con layout adattivi e split view.",
                    detailedDescription: "Univr Calendar ora è completamente ottimizzato per iPad! Goditi un'esperienza fluida con layout adattivi, split view per visualizzare le settimane in landscape e interfaccia pensata appositamente per schermi più grandi. Ogni elemento è stato ripensato per sfruttare al meglio lo spazio disponibile."
                ),
                WhatsNewFeature(
                    icon: "wifi.slash",
                    iconColor: .orange,
                    title: "Modalità Offline",
                    shortDescription: "Consulta le tue lezioni anche senza connessione, sincronizzazione automatica.",
                    detailedDescription: "Niente più preoccupazioni per la connessione! L'app rileva in tempo reale quando sei offline e ti avvisa con un indicatore dedicato, permettendoti di consultare le lezioni salvate. L'onboarding e le impostazioni si bloccano automaticamente senza rete. Appena torni online, tutto si sincronizza in background senza alcun intervento da parte tua."
                ),
                WhatsNewFeature(
                    icon: "sparkles",
                    iconColor: .purple,
                    title: "Interfaccia Rinnovata",
                    shortDescription: "Sheet personalizzate, animazioni fluide ed effetti liquid glass.",
                    detailedDescription: "Le sheet di sistema sono state sostituite da una sheet completamente personalizzata, costruita con UIKit, che offre gesture avanzate, effetti liquid glass dinamici e un controllo totale sulle animazioni. Su iPad il corner radius della sheet si adatta automaticamente alla posizione della finestra. Il risultato? Un'app ancora più bella e piacevole da usare."
                ),
                WhatsNewFeature(
                    icon: "wrench.and.screwdriver",
                    iconColor: .gray,
                    title: "Miglioramenti e Correzioni",
                    shortDescription: "Bug fix, performance migliorate e supporto per iOS 17/18.",
                    detailedDescription: "• Nuovo stile per le lezioni cancellate con bordo e testo barrato\n• Hover effects su iPad per un'interazione più naturale\n• Picker data e ora completamente ridisegnati con performance migliorate\n• Mappa dell'aula ora statica per maggiore stabilità e velocità\n• Risolti numerosi bug con la sheet personalizzata su iOS 17 e 18\n• Supporto ottimizzato per iOS 17, 18 e iPadOS\n• Dettagli lezione ridisegnati con layout migliorato\n• Performance generali notevolmente migliorate"
                )
            ]
        ),
        WhatsNewVersion(
            version: "0.8",
            date: "2025-12-12",
            headline: "Donazioni, nuova ricerca e velocità",
            features: [
                WhatsNewFeature(
                    icon: "cup.and.saucer",
                    iconColor: .blue,
                    title: "Sezione Donazioni",
                    shortDescription: "Supporta lo sviluppatore con una donazione direttamente dall'app.",
                    detailedDescription: "Nelle impostazioni è stata aggiunta una nuova sezione con un link per effettuare una donazione allo sviluppatore tramite Revolut. Se l'app ti è utile, ora puoi mostrare il tuo apprezzamento con un piccolo contributo. Grazie di cuore!"
                ),
                WhatsNewFeature(
                    icon: "list.bullet.rectangle",
                    iconColor: .orange,
                    title: "Selezione Corso Ridisegnata",
                    shortDescription: "La ricerca del corso è stata ripensata da zero con un nuovo componente.",
                    detailedDescription: "L'interfaccia di selezione del corso è stata completamente riscritta in un componente dedicato condiviso tra onboarding e impostazioni. La barra di ricerca ora ha un pulsante per cancellare il testo, i risultati si caricano in modo più fluido e lo stile è stato uniformato con sfondi adattivi al tema del sistema."
                ),
                WhatsNewFeature(
                    icon: "bolt.fill",
                    iconColor: .purple,
                    title: "Prestazioni in Background",
                    shortDescription: "L'elaborazione dei dati avviene ora interamente in background.",
                    detailedDescription: "L'organizzazione del calendario, la generazione del date picker e tutte le operazioni di lettura e scrittura della cache vengono ora eseguite in background. I campi delle lezioni come durata, nome pulito e tag sono pre-calcolati al caricamento, rendendo lo scorrimento istantaneo."
                ),
                WhatsNewFeature(
                    icon: "wrench.and.screwdriver",
                    iconColor: .gray,
                    title: "Miglioramenti e Correzioni",
                    shortDescription: "Architettura rinnovata, animazioni fluide e tanti fix.",
                    detailedDescription: "• Navigazione semplificata: ContentView e RootView unite in un'unica vista\n• Aggiornamento a Swift 6.2 con Strict Concurrency per maggiore stabilità\n• Cache convertita in actor per sicurezza tra thread garantita\n• Logica di onboarding e impostazioni unificata in un componente condiviso\n• Crediti nella pagina Info ora interattivi con link al portfolio\n• Placeholder di caricamento migliorato con più elementi e shimmer rinnovato\n• Animazioni più fluide nell'onboarding con transizioni snappy\n• Costanti dell'app centralizzate per una manutenzione più semplice"
                )
            ]
        ),
        WhatsNewVersion(
            version: "0.7",
            date: "2025-12-04",
            headline: "Due lingue, splash screen e crediti",
            features: [
                WhatsNewFeature(
                    icon: "globe",
                    iconColor: .blue,
                    title: "Italiano e Inglese",
                    shortDescription: "L'app è ora completamente tradotta in italiano e inglese.",
                    detailedDescription: "Ogni testo dell'app è stato tradotto: dall'onboarding alle impostazioni, dai messaggi di errore ai dettagli delle lezioni. La lingua si adatta automaticamente a quella impostata sul dispositivo, così l'esperienza è naturale fin dal primo avvio."
                ),
                WhatsNewFeature(
                    icon: "sparkle",
                    iconColor: .orange,
                    title: "Splash Screen Animato",
                    shortDescription: "L'app si apre con un'animazione che porta l'icona nell'onboarding.",
                    detailedDescription: "All'apertura dell'app viene mostrata una splash screen con l'icona che, al primo avvio, si anima e si sposta fluida nella pagina di benvenuto dell'onboarding grazie a una transizione coordinata. Se hai già completato la configurazione, la splash scompare rapidamente."
                ),
                WhatsNewFeature(
                    icon: "gearshape",
                    iconColor: .purple,
                    title: "Impostazioni Rinnovate",
                    shortDescription: "Nuove icone, sezione Info con versione e crediti, e conferma reset.",
                    detailedDescription: "Le impostazioni hanno un look completamente nuovo con icone per ogni voce e una migliore organizzazione. È stata aggiunta la sezione Info con la versione dell'app, i crediti e i contributori. La ricerca dei corsi ora ha una lista scorrevole con pulsante di chiusura e il reset dell'app richiede una conferma per evitare errori."
                ),
                WhatsNewFeature(
                    icon: "wrench.and.screwdriver",
                    iconColor: .gray,
                    title: "Miglioramenti e Correzioni",
                    shortDescription: "Pause ridisegnate, lezioni annullate e preparazione TestFlight.",
                    detailedDescription: "• Le pause tra le lezioni mostrano ora un'icona tazza al posto del testo semplice\n• Le lezioni con sfondo bianco su tema chiaro hanno ora un bordo visibile\n• Le lezioni annullate appaiono ora con opacità ridotta per distinguerle meglio\n• Separata l'architettura dell'app in modulo Apple e modulo multipiattaforma\n• Preparata l'app per la distribuzione su TestFlight con privacy manifest e nuovo Bundle ID\n• Corretti bug nel reset dell'app e nella riapertura della sheet"
                )
            ]
        ),
        WhatsNewVersion(
            version: "0.6",
            date: "2025-12-02",
            headline: "Lezioni più leggibili e nuova icona",
            features: [
                WhatsNewFeature(
                    icon: "textformat.abc",
                    iconColor: .blue,
                    title: "Nomi Lezioni Semplificati",
                    shortDescription: "I nomi dei corsi vengono abbreviati automaticamente e mostrano tag utili.",
                    detailedDescription: "I nomi delle lezioni vengono ora formattati in modo intelligente: parole come \"Laboratorio\" o \"Teoria\" diventano tag colorati sotto il nome, le parentesi e le informazioni tecniche vengono estratte e semplificate. Il risultato è un nome più corto e leggibile a colpo d'occhio."
                ),
                WhatsNewFeature(
                    icon: "rectangle.grid.1x2",
                    iconColor: .orange,
                    title: "Card Lezione Ridisegnata",
                    shortDescription: "Nuovo layout con orario a sinistra, dettagli a destra e tag colorati.",
                    detailedDescription: "La scheda di ogni lezione ha un aspetto completamente nuovo: l'orario di inizio e la durata sono a sinistra, il nome del corso, l'aula e i tag a destra. Il gradiente è stato sostituito da un colore pieno proveniente dall'università, per un look più pulito e coerente."
                ),
                WhatsNewFeature(
                    icon: "app.badge",
                    iconColor: .purple,
                    title: "Prima Icona dell'App",
                    shortDescription: "Univr Calendar ha finalmente la sua icona personalizzata.",
                    detailedDescription: "L'app ha ora un'icona dedicata con un design che richiama il calendario e la lente d'ingrandimento, pensata per essere riconoscibile fin dalla schermata principale del dispositivo."
                ),
                WhatsNewFeature(
                    icon: "wrench.and.screwdriver",
                    iconColor: .gray,
                    title: "Miglioramenti e Correzioni",
                    shortDescription: "Calendario localizzato, dettagli migliorati e vari fix.",
                    detailedDescription: "• Il calendario ora rispetta la lingua impostata sul dispositivo dell'utente\n• I simboli del giorno e del mese sono ora capitalizzati correttamente\n• Migliorato il layout della schermata dettagli lezione con data, orario, docente e capienza\n• Corretti problemi con la cache degli anni accademici\n• Risolti bug nell'aggiornamento delle date del calendario\n• Impedito di navigare verso giorni non disponibili nel calendario"
                )
            ]
        ),
        WhatsNewVersion(
            version: "0.5",
            date: "2025-11-27",
            headline: "Dettagli lezione e velocità al top",
            features: [
                WhatsNewFeature(
                    icon: "info.circle",
                    iconColor: .blue,
                    title: "Dettagli della Lezione",
                    shortDescription: "Tocca una lezione per vedere tutte le informazioni e la mappa dell'aula.",
                    detailedDescription: "Ora puoi toccare qualsiasi lezione per aprire una schermata dettagliata con orario, docente, aula e una mappa interattiva che mostra la posizione approssimativa dell'edificio. Puoi anche toccare il titolo per vedere il nome completo del corso."
                ),
                WhatsNewFeature(
                    icon: "hare",
                    iconColor: .orange,
                    title: "Performance Migliorate",
                    shortDescription: "Caricamento più veloce del 40% e transizioni fluide nella sheet.",
                    detailedDescription: "L'organizzazione dei dati è stata ottimizzata con un miglioramento di circa il 40% nei tempi di elaborazione. Molti valori vengono ora pre-calcolati al primo caricamento, così le schermate si aprono istantaneamente. Anche la sheet in basso ha nuove animazioni di opacità dinamiche che rendono le transizioni più naturali."
                ),
                WhatsNewFeature(
                    icon: "arrow.triangle.2.circlepath",
                    iconColor: .purple,
                    title: "Cache di Rete",
                    shortDescription: "I dati scaricati vengono salvati e aggiornati in automatico.",
                    detailedDescription: "Le informazioni su anni, corsi e anni accademici vengono ora salvate localmente dopo il primo download. Alle aperture successive l'app li carica dalla cache e verifica in background se ci sono aggiornamenti, rendendo la navigazione molto più rapida."
                ),
                WhatsNewFeature(
                    icon: "wrench.and.screwdriver",
                    iconColor: .gray,
                    title: "Miglioramenti e Correzioni",
                    shortDescription: "Calendario più fluido, colori ottimizzati e tanti bug fix.",
                    detailedDescription: "• Risolto definitivamente il bug che all'apertura non selezionava il giorno corretto\n• Ottimizzata la conversione dei colori con un sistema di cache dedicato\n• Migliorata l'estrazione JSON con regex più performanti\n• Il calendario non si muove più in modo irregolare durante lo scroll\n• Date picker e calendario compatto ora usano cache interna per rigenerarsi senza ricalcolare tutto"
                )
            ]
        ),
        WhatsNewVersion(
            version: "0.4",
            date: "2025-11-23",
            headline: "Avvio più veloce e design adattivo",
            features: [
                WhatsNewFeature(
                    icon: "bolt.fill",
                    iconColor: .blue,
                    title: "Avvio Rapido con la Cache",
                    shortDescription: "L'app carica i dati salvati e controlla aggiornamenti in automatico.",
                    detailedDescription: "Ora all'apertura l'app carica istantaneamente le lezioni salvate in precedenza, senza attendere la rete. In background viene verificata la disponibilità di aggiornamenti: se ci sono novità, un avviso ti permette di aggiornare i dati quando preferisci."
                ),
                WhatsNewFeature(
                    icon: "antenna.radiowaves.left.and.right",
                    iconColor: .orange,
                    title: "Rete Più Affidabile",
                    shortDescription: "Messaggi di errore chiari e una connessione più stabile.",
                    detailedDescription: "Il sistema di rete è stato riscritto con un metodo più affidabile per estrarre i dati dal server. I messaggi di errore sono ora specifici e in italiano, così puoi capire subito cosa è andato storto senza dover interpretare codici tecnici."
                ),
                WhatsNewFeature(
                    icon: "paintbrush.pointed",
                    iconColor: .purple,
                    title: "Interfaccia su Misura",
                    shortDescription: "Le finestre seguono la curvatura reale del tuo dispositivo.",
                    detailedDescription: "Il raggio degli angoli delle finestre sovrapposte ora si adatta automaticamente al modello del tuo iPhone o iPad, per un aspetto più armonioso e naturale. Anche i numeri e i nomi dei giorni nel calendario sono stati uniformati per una lettura più chiara."
                ),
                WhatsNewFeature(
                    icon: "wrench.and.screwdriver",
                    iconColor: .gray,
                    title: "Miglioramenti e Correzioni",
                    shortDescription: "Impostazioni centralizzate, date migliorate e vari fix.",
                    detailedDescription: "• Le impostazioni dell'app sono state centralizzate in un unico punto, più affidabili e condivise ovunque\n• Corretta la selezione del giorno all'apertura dell'app che non sempre andava al giorno giusto\n• Migliorato il calendario con stati disabilitati più chiari e interazioni più precise\n• Aggiunto un messaggio dedicato quando non vengono trovate lezioni per il corso selezionato\n• Numerosi bug fix nella navigazione e nella gestione delle date"
                )
            ]
        ),
        WhatsNewVersion(
            version: "0.3",
            date: "2025-11-20",
            headline: "Nuovo benvenuto e compatibilità iOS",
            features: [
                WhatsNewFeature(
                    icon: "hand.point.up.left.and.text",
                    iconColor: .blue,
                    title: "Pagina di Benvenuto",
                    shortDescription: "Una nuova schermata introduttiva apre l'onboarding.",
                    detailedDescription: "L'onboarding ora inizia con una pagina di benvenuto che presenta l'app e il suo scopo. Un modo più accogliente per guidarti nella configurazione iniziale, con la possibilità in futuro di includere un'animazione dedicata."
                ),
                WhatsNewFeature(
                    icon: "arrow.left.arrow.right",
                    iconColor: .orange,
                    title: "Scorri le Settimane",
                    shortDescription: "Cambia settimana con uno swipe dal calendario compatto.",
                    detailedDescription: "Nel calendario compatto in basso puoi ora scorrere a sinistra o a destra per passare alla settimana precedente o successiva. Il primo giorno della nuova settimana viene selezionato automaticamente."
                ),
                WhatsNewFeature(
                    icon: "square.stack.3d.up",
                    iconColor: .purple,
                    title: "Architettura MVVM",
                    shortDescription: "Logica e interfaccia ora sono completamente separate.",
                    detailedDescription: "L'app è stata ristrutturata con il pattern MVVM: la logica di caricamento lezioni, organizzazione dati e rete è ora gestita da ViewModel dedicati per il calendario, l'onboarding e le impostazioni."
                ),
                WhatsNewFeature(
                    icon: "iphone.gen2",
                    iconColor: .green,
                    title: "Supporto iOS 17 e 18",
                    shortDescription: "Compatibilità estesa alle versioni precedenti di iOS.",
                    detailedDescription: "L'app è ora retrocompatibile con iOS 17 e 18 grazie a fallback dedicati per i componenti più recenti. Stili dei pulsanti, effetti visivi e layout si adattano automaticamente alla versione del sistema."
                ),
                WhatsNewFeature(
                    icon: "wrench.and.screwdriver",
                    iconColor: .gray,
                    title: "Miglioramenti e Correzioni",
                    shortDescription: "Rete migliorata, file riorganizzati e vari fix.",
                    detailedDescription: "• Migliorato il parsing JSON delle risposte di rete per una maggiore affidabilità\n• Riorganizzati tutti i file in cartelle dedicate (App, Core, UI)\n• Le viste sono state separate in file distinti per una gestione più semplice\n• Le estensioni sono state divise tra logica e UI per facilitare future migrazioni\n• Corretti numerosi bug nella navigazione e nel caricamento"
                )
            ]
        ),
        WhatsNewVersion(
            version: "0.2",
            date: "2025-11-19",
            headline: "Scorri i giorni e nuovo calendario",
            features: [
                WhatsNewFeature(
                    icon: "hand.draw",
                    iconColor: .blue,
                    title: "Scorri tra i Giorni",
                    shortDescription: "Passa da un giorno all'altro con uno swipe orizzontale.",
                    detailedDescription: "Ora puoi navigare tra i giorni direttamente dalla schermata principale con uno swipe a destra o sinistra. Ogni giorno mostra le sue lezioni, le pause e un messaggio se non ci sono lezioni. Tutto l'anno accademico è già pronto per essere sfogliato."
                ),
                WhatsNewFeature(
                    icon: "calendar",
                    iconColor: .red,
                    title: "Calendario Personalizzato",
                    shortDescription: "Un nuovo calendario mensile sostituisce quello di sistema.",
                    detailedDescription: "Il calendario di sistema è stato sostituito con uno personalizzato, pensato per adattarsi meglio all'app. Puoi navigare tra i mesi e selezionare qualsiasi giorno in modo più rapido e intuitivo."
                ),
                WhatsNewFeature(
                    icon: "bolt.horizontal",
                    iconColor: .orange,
                    title: "Rete più Moderna",
                    shortDescription: "Le chiamate di rete ora usano async/await per una maggiore affidabilità.",
                    detailedDescription: "Tutte le funzioni di rete sono state riscritte con async/await e Task, sostituendo il vecchio sistema a callback. Il risultato è un caricamento più stabile e reattivo, con una gestione degli errori più chiara."
                ),
                WhatsNewFeature(
                    icon: "wrench.and.screwdriver",
                    iconColor: .gray,
                    title: "Miglioramenti e Correzioni",
                    shortDescription: "Riorganizzazione interna e vari bug risolti.",
                    detailedDescription: "• Aggiunte numerose utility per lavorare con le date in modo più semplice\n• Rimosso SwiftData dal progetto, non più necessario\n• Rinominato il file dei modelli per una struttura più chiara\n• Aggiunto un identificativo univoco alle lezioni\n• Corretti diversi bug nella navigazione e nel calendario"
                )
            ]
        ),
        WhatsNewVersion(
            version: "0.1",
            date: "2025-10-20",
            headline: "Nasce l'app, tutto parte da qui",
            features: [
                WhatsNewFeature(
                    icon: "app.badge.checkmark",
                    iconColor: .blue,
                    title: "Nasce Univr Calendar",
                    shortDescription: "Visualizza le tue lezioni del giorno, scegli il corso e inizia subito.",
                    detailedDescription: "Univr Calendar nasce con tutto il necessario per partire: una schermata principale che mostra le lezioni del giorno, un onboarding guidato per scegliere anno accademico e corso di laurea, e le impostazioni per cambiare le tue preferenze in qualsiasi momento."
                ),
                WhatsNewFeature(
                    icon: "calendar.badge.clock",
                    iconColor: .green,
                    title: "Pulsante Calendario",
                    shortDescription: "Si apre e chiude in automatico mentre scorri le lezioni.",
                    detailedDescription: "Il nuovo pulsante Calendario nella barra in basso si comporta in modo intelligente: si apre quando torni in cima alla lista, si chiude quando scorri verso il basso e si riapre quando passi al giorno successivo. Così hai sempre le informazioni giuste al momento giusto."
                ),
                WhatsNewFeature(
                    icon: "magnifyingglass",
                    iconColor: .teal,
                    title: "Ricerca Corsi",
                    shortDescription: "Trova il tuo corso in un attimo con la barra di ricerca.",
                    detailedDescription: "Non devi più scorrere l'intera lista: basta digitare il nome del corso e la lista si filtra istantaneamente. Disponibile sia durante la configurazione iniziale sia nelle impostazioni."
                ),
                WhatsNewFeature(
                    icon: "person.text.rectangle",
                    iconColor: .orange,
                    title: "Matricola Intelligente",
                    shortDescription: "La scelta pari/dispari appare solo quando il corso lo richiede.",
                    detailedDescription: "L'app rileva automaticamente se il tuo corso prevede la distinzione tra matricole pari e dispari. Se non serve, la pagina viene saltata nell'onboarding e nascosta nelle impostazioni, rendendo tutto più semplice e veloce."
                ),
                WhatsNewFeature(
                    icon: "bolt.fill",
                    iconColor: .purple,
                    title: "Caricamenti Più Veloci",
                    shortDescription: "I dati vengono caricati una sola volta e riutilizzati ovunque.",
                    detailedDescription: "Anni, corsi e anni accademici vengono scaricati una volta e condivisi tra tutte le schermate. Le impostazioni non ricaricano più i dati se sono già disponibili, rendendo la navigazione più fluida e riducendo i tempi di attesa."
                ),
                WhatsNewFeature(
                    icon: "wrench.and.screwdriver",
                    iconColor: .gray,
                    title: "Miglioramenti e Correzioni",
                    shortDescription: "Vari bug risolti e miglioramenti di stabilità.",
                    detailedDescription: "• Corretto un problema che impediva di visualizzare le lezioni degli anni precedenti\n• Risolto un errore nel filtro che nascondeva alcune lezioni per corsi senza distinzione matricola\n• Migliorato il supporto al tema chiaro nell'indicatore di caricamento\n• Migliorata la compatibilità con diverse dimensioni di schermo"
                )
            ]
        )
    ]
    
    static var latestVersion: WhatsNewVersion? {
        versions.first
    }
}

// MARK: - WhatsNewView

struct WhatsNewView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var previousVersionIndex: Int = 0
    @State private var selectedVersionIndex: Int = 0 {
        didSet { previousVersionIndex = oldValue }
    }
    @State private var expandedFeatures: Set<UUID> = []
    @State private var showAllExpanded: Bool = false
    
    private var currentVersion: WhatsNewVersion? {
        guard WhatsNewData.versions.indices.contains(selectedVersionIndex) else { return nil }
        return WhatsNewData.versions[selectedVersionIndex]
    }
    
    private var canGoNewer: Bool {
        selectedVersionIndex > 0
    }
    
    private var canGoOlder: Bool {
        selectedVersionIndex < WhatsNewData.versions.count - 1
    }
    
    private let animation: Animation = .interactiveSpring(response: 0.25, dampingFraction: 1)
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(WhatsNewData.versions.enumerated()), id: \.element.id) { index, version in
                    versionContent(version)
                        .containerRelativeFrame(.horizontal)
                        .contentMargins(.top, 126)
                        .contentMargins(.bottom, 86)
                        .id(index)
                        .ignoresSafeArea()
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: Binding(
            get: { selectedVersionIndex },
            set: { newValue in
                if let val = newValue {
                    selectedVersionIndex = val
                }
            }
        ))
        .animation(animation, value: selectedVersionIndex)
        .onChange(of: selectedVersionIndex) {
            expandedFeatures.removeAll()
            showAllExpanded = false
        }
        .onChange(of: expandedFeatures) {
            showAllExpanded = expandedFeatures.count == WhatsNewData.versions[selectedVersionIndex].features.count
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                headerView
            }
            
            ToolbarItem(placement: .bottomBar) {
                navigatorArrow(direction: .left)
            }
            
            ToolbarItem(placement: .bottomBar) {
                Spacer()
            }
            
            ToolbarItem(placement: .bottomBar) {
                navigator
            }
            
            ToolbarItem(placement: .bottomBar) {
                Spacer()
            }
            
            ToolbarItem(placement: .bottomBar) {
                navigatorArrow(direction: .right)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("Novità ")
                
                Text(currentVersion?.version ?? "")
                    .foregroundStyle(.secondary)
            }
            .font(.largeTitle)
            .fontWeight(.bold)
            
            Text(currentVersion?.headline ?? " ")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 70)
        .contentTransition(.numericText(countsDown: previousVersionIndex < selectedVersionIndex))
        .animation(animation, value: selectedVersionIndex)
    }
    
    // MARK: - Version Content
    
    private func versionContent(_ version: WhatsNewVersion) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                Button {
                    guard let version = currentVersion else { return }
                    
                    Haptics.play(.impact(flexibility: .soft, intensity: 0.6))
                    if showAllExpanded {
                        expandedFeatures.removeAll()
                    } else {
                        version.features.filter { $0.hasDetails }.forEach {
                            expandedFeatures.insert($0.id)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showAllExpanded ? "rectangle.compress.vertical" : "rectangle.expand.vertical")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .symbolReplace()
                        
                        Text(showAllExpanded ? "Comprimi tutto" : "Espandi tutto")
                            .font(.caption)
                            .fontWeight(.medium)
                            .contentTransition(.numericText())
                    }
                    .foregroundStyle(.primary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        Capsule()
                            .fill(.background)
                            .strokeBorder(.tertiary, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                ForEach(version.features, id: \.id) { feature in
                    FeatureCard(
                        feature: feature,
                        isExpanded: expandedFeatures.contains(feature.id),
                        animation: animation,
                        onToggle: {
                            if expandedFeatures.contains(feature.id) {
                                expandedFeatures.remove(feature.id)
                            } else {
                                expandedFeatures.insert(feature.id)
                            }
                        }
                    )
                }
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .animation(animation, value: expandedFeatures)
    }
    
    // MARK: - Version Navigator
    enum ArrowDirection {
        case left
        case right
    }
    
    private func navigatorArrow(direction: ArrowDirection) -> some View {
        Button {
            selectedVersionIndex -= direction == .left ? 1 : -1
        } label: {
            Image(systemName: direction == .left ? "chevron.left" : "chevron.right")
                .fontWeight(.semibold)
                .frame(width: 36, height: 36)
        }
        .opacity(direction == .left ? canGoNewer ? 1 : 0.3 : canGoOlder ? 1 : 0.3)
        .disabled(direction == .left ? !canGoNewer : !canGoOlder)
        .sensoryFeedback(.selection, trigger: selectedVersionIndex)
    }
    
    private var navigator: some View {
        ZStack {
            if let version = currentVersion {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        ForEach(Array(WhatsNewData.versions.enumerated()), id: \.element.id) { index, v in
                            Circle()
                                .fill(index == selectedVersionIndex ? Color.primary : Color.secondary.opacity(0.3))
                                .frame(width: index == selectedVersionIndex ? 8 : 6, height: index == selectedVersionIndex ? 8 : 6)
                        }
                    }
                    
                    Text(version.date, format: .dateTime.day().month(.abbreviated).year())
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .contentTransition(.numericText(countsDown: previousVersionIndex < selectedVersionIndex))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .animation(animation, value: selectedVersionIndex)
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let feature: WhatsNewFeature
    let isExpanded: Bool
    let animation: Animation
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                // Icon
                Image(systemName: feature.icon)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(feature.iconColor)
                    .symbolEffect(.bounce, value: isExpanded)
                    .frame(width: 48, height: 48)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(feature.iconColor.opacity(0.12))
                    }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(feature.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(feature.shortDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 0)
                
                // Expand indicator
                if feature.hasDetails {
                    Image(systemName: "chevron.down.circle")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            
            // Expanded details
            if isExpanded, let details = feature.detailedDescription {
                VStack(alignment: .leading, spacing: 14) {
                    Rectangle()
                        .fill(.tertiary)
                        .frame(height: 1)
                    
                    Text(details)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.background)
                .strokeBorder(.tertiary, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .onTapGesture {
            if feature.hasDetails {
                Haptics.play(.impact(flexibility: .soft, intensity: 0.6))
                onToggle()
            }
        }
        .hoverEffect(.lift)
        .animation(animation, value: isExpanded)
    }
}

// MARK: - Preview

#Preview {
    WhatsNewView()
}
