# laden-filtern-aufbereiten.R - Ein einfaches R-Skript
# 
# Für das Seminar "Datenjournalismus" im Sommersemester 2022
# Hochschule Mainz, Studiengang Digital Media, 6. Semester
#
# CC-BY Jan Eggers

cat("Gude, Welt!")

# Das hier ist ein Kommentar. Wo eine Raute davorsteht, das ignoriert der Computer.

# ---- Libraries laden ----

# Libraries, Bibliotheksfunktionen, erweitern R um wichtige Funktionen. 
# Die entsprechenden Pakete müssen installiert sein. 
# Die hier braucht man übrigens eigentlich fast immer. 

library(readr)      # CSVs einlesen

library(dplyr)      # Eine Bibliothek aus dem so genannten "Tidyverse", 
                    # eine Sammlung von Bibliotheken, die verflucht logisch und durchdacht ist - 
                    # manchmal allerdings auch frustrierend und kompliziert. 
                    # Ich schreibe in fast alle meine Skripte erst mal "library(tidyverse)"
                    # und habe dann auch dplyr mit drin. 
library(stringr)    # Auch aus dem Tidyverse: String- (Zeichenketten-) Funktionen
library(lubridate)  # Datumsangaben hin- und herbewegen. (Brauchen wir hier allerdings nicht.)

# library(readxl)   #  - nehme ich praktisch nicht mehr, weil...
library(openxlsx)   # ...diese Library eine Allzweckwaffe ist, mit der man Excel-Dateien nicht nur
                    # super lesen kann, sondern auch erzeugen und schreiben. 
                    # (Allerdings: wenn man Excel-tabellen mit mehreren Blättern und Formatierungen
                    # anlegen will, wird's auch hier ein wenig komplizierter)


# Einfach immer stur Strg-Return drücken, um eine Zeile nach der anderen auszuführen. 
print("Gude, Welt!")

# Zeig an, welche Libraries geladen sind: 
# Wir tun die geladenen Libraries einfach in eine Variable. 
# Das kann man bei R einfach so tun, ohne vorher was definieren zu müssen.

# Unsere neue Variable my_libraries kriegt jetzt die Namen aller geladene Bibliotheken zugewiesen: 
my_libraries <- library()$results[,1]

# Statt mit Strg-Return weiterzuspringen: 
# Einfach mal auf die Kommandozeile wechseln (Strg-2), dann my_libraries eingeben und Return.

# Mit Strg-1 springt man wieder zurück ins Editor-Fenster

cat("Geladene Bibliotheken: \n",my_libraries)
cat("\n\nKeine Angst, muss man nicht verstehen. Und cat() ist wie print()")
# ---- Teil 1: Die CSV-Dateien einlesen ----

# Hier lesen wir das erste CSV ein: 12411-04-02-4-B.csv


# Das ist ein ordentliches CSV. 
# - Die Werte/Spalten sind durch Semikolons (";") voneinander getrennt. 
# - Der Zeichensatz ist für Windows
# - Zeichenketten sind in Anführungszeichen eingeschlossen. 
# Allerdings: Die ersten 6 Zeilen enthalten Kommentare und gehören übersprungen.

# Datei muss im Arbeitsverzeichnis liegen. 

altersgruppen_df <- read_delim("daten/12411-04-02-4.csv", 
                               delim = ";", 
                               escape_double = FALSE, 
                               col_types = cols(Insgesamt = col_integer(), 
                                                männlich = col_integer(), 
                                                weiblich = col_integer()), 
                               locale = locale(date_names = "de", 
                                               decimal_mark = ",", grouping_mark = ".",
                                               encoding = "ISO-8859-1"), 
                               trim_ws = TRUE, 
                               skip = 6) %>% 
  rename(AGS = 1, 
         Name = 2, 
         Altersgruppe = 3) %>% 
  
  # Das Symbol %>% - die Adleraugen werden auch entdeckt haben, dass es auf
  # meinem Laptop klebt - ist was Besonderes. Zumal es gar nicht zu R gehört, sondern
  # erst über eine Bibliothek namens magrittr nachgerüstet wird (die aber zu 
  # dplyr und damit zum Tidyverse gehört). Das %>% ist das *Pipe-Symbol*.
  #
  # Pipe-Symbole sparen einem Klammern und Schachtelungen, weil sie mich ohne
  # großen Aufwand mit dem vorigen Ergebnis weiterrechnen lassen: 
  # 
  # Anstatt dass ich zwei Befehle schachtele (rename (read_delim(...)),...)
  # setze ich sie hintereinander: 
  # read_delim(...) %>% rename(...)
  # Und jetzt geht's gerade weiter: 
  # Filtere alles aus, was nicht fünfstellig ist. 
  filter(str_detect(AGS,"^.....$")) 



# _df muss man nicht dazuschreiben, ich mache das zur Klarheit: 
# altersgruppen_df ist ein so genanntes "Data Frame", eine der Grundstrukturen von R: 
# Eine Tabelle  - mit etwas Verpackung, also Metadaten,
# zum Beispiel Spalten-Bezeichnern. und Dateityp der jeweiligen Spalte
# Keine Sorge, ist ganz einfach, wir schauen uns gleich eins an. 

View(altersgruppen_df)

hessen_ag_df <- altersgruppen_df %>% 
  filter(str_detect(AGS,"^06")) %>% 
  filter(Altersgruppe != "Insgesamt") %>% 
  # Jetzt summieren wir die Bevölkerung in diesem Kreis auf
  group_by(AGS) %>% 
  summarize(Insgesamt = sum(Insgesamt))

# Alternative zu view(): Druck die ersten sechs Zeilen aus (oder mehr, wenn angegeben) 
head(hessen_ag_df)

# ---- Teil 2: Eine große Tabelle bearbeiten ----
rki_url <- "https://media.githubusercontent.com/media/robert-koch-institut/SARS-CoV-2_Infektionen_in_Deutschland/master/Aktuell_Deutschland_SarsCov2_Infektionen.csv"
rki_df <- read_csv(rki_url)  %>% 
  # IdLandkreis in char, Landkreis-Namen für Hessen ergänzen
  mutate(IdLandkreis =ifelse(IdLandkreis>9999,
                             as.character(IdLandkreis),
                             paste0("0",IdLandkreis)))

# Fälle letzte 7 Tage nach Landkreis
rki7d <- rki_df %>% 
  filter(Meldedatum >= today()-7) %>% 
  filter(NeuerFall %in% c(0,1)) %>% 
  select(AGS = IdLandkreis, AnzahlFall) %>% 
  group_by(AGS) %>% 
  summarize(Fälle = sum(AnzahlFall)) %>%
  ungroup()

rki_hessen_inzidenz <- rki7d %>% 
  right_join(hessen_ag, by = "AGS") %>% 
  mutate(inz7t = Fälle / Insgesamt *100000)
