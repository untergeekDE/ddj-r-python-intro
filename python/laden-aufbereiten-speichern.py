# laden-aufbereiten-speichern.py
# Einfaches Programm zum Umgang mit Daten
#
# Tabellen-Funktionen laden

# Bibliotheken für Tabellen laden
import pandas as pd
import numpy as np

# aus dem RKI-Github die aktuelle Falldatenbank lesen
rki_url = "https://media.githubusercontent.com/media/robert-koch-institut/SARS-CoV-2_Infektionen_in_Deutschland/master/Aktuell_Deutschland_SarsCov2_Infektionen.csv"
rki_df = pd.read_csv(rki_url)

# Erste Zeilen ausgeben
rki_df.head(5)

# Jetzt filtern: Hessen
rki_hessen_df = rki_df.loc[(rki_df["IdLandkreis"] >= 6000) & (rki_df["IdLandkreis"]< 7000)]
rki_hessen_df.head(5)

# Bibliotheken zum Umgang mit Datumsformaten
from datetime import date, timedelta
from dateutil.parser import parse

# Daten ordentlich formatieren: ganze Tabelle durchgehen
for i in rki_hessen_df.index:
    rki_hessen_df.loc[i,'IdLandkreis'] = "0"+str(rki_hessen_df.IdLandkreis[i])
    rki_hessen_df.loc[i,'Meldedatum'] = parse(rki_hessen_df.Meldedatum[i]).date()
    rki_hessen_df.loc[i,'Refdatum'] = parse(rki_hessen_df.Refdatum[i]).date()
    
rki_hessen_df.head(5)

# Jetzt: Alle Fälle 2022 filtern, Tabelle nach Meldedatum ausgeben.
mein_df = rki_hessen_df.loc[rki_hessen_df["Meldedatum"] >= date(2022,1,1)]
neufaelle_df = pd.pivot_table(mein_df,index=["Meldedatum"],values=["AnzahlFall"],aggfunc=np.sum)
neufaelle_df.head(5)

# Jetzt: Fälle 2022 Hessen
faelle_nach_alter_df = pd.pivot_table(mein_df,index=["Meldedatum"],columns=["Altersgruppe"],values=["AnzahlFall"],aggfunc=np.sum,fill_value = 0)
faelle_nach_alter_df.head(5)

# Ausgeben!
faelle_nach_alter_df.to_excel ('daten/export.xlsx', header=True)

