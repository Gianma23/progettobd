SET FOREIGN_KEY_CHECKS = 0;
DROP DATABASE IF EXISTS smart_home;
CREATE DATABASE smart_home; 
USE smart_home;

-- ================= --
-- 	   Documento     --
-- ================= --
DROP TABLE IF EXISTS Documento;
CREATE TABLE Documento (
	Numero 			VARCHAR(10) NOT NULL,
	Tipologia		VARCHAR(50) NOT NULL,
    Scadenza		DATE NOT NULL,
    Ente			VARCHAR(100) NOT NULL, 
    PRIMARY KEY(Numero)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================= --
-- 	   	Utente       --
-- ================= --
DROP TABLE IF EXISTS Utente;
CREATE TABLE Utente (
	CodFiscale 		VARCHAR(16) NOT NULL,
    Nome			VARCHAR(59) NOT NULL,
    Cognome			VARCHAR(50) NOT NULL, 
	DataNascita		DATE NOT NULL,
    NumTelefono		VARCHAR(10) NOT NULL,
    Documento		VARCHAR(10) NOT NULL,
    PRIMARY KEY(CodFiscale),
    
    FOREIGN KEY(Documento) REFERENCES Documento(Numero)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================= --
-- 	   	Account      --
-- ================= --
DROP TABLE IF EXISTS Account;
CREATE TABLE Account (
	Nickname 			VARCHAR(10) NOT NULL,
    Password			VARCHAR(50) NOT NULL,
							CHECK(LENGTH(password)>=8),
    DomandaSicurezza	VARCHAR(100) NOT NULL, 
	RispostaSicurezza	VARCHAR(50) NOT NULL,
    DataIscrizione		DATE NOT NULL,
    Utente				VARCHAR(16) NOT NULL,
    NumInterazioni		INT NOT NULL DEFAULT 0,
    PRIMARY KEY(Nickname),
    
    FOREIGN KEY(Utente) REFERENCES Utente(CodFiscale)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================= --
-- 	   	Stanza       --
-- ================= --
DROP TABLE IF EXISTS Stanza;
CREATE TABLE Stanza (
	IDStanza 			INT NOT NULL AUTO_INCREMENT,
    Nome				VARCHAR(50) NOT NULL,
    Larghezza			DOUBLE, 
	Lunghezza			DOUBLE,
    Altezza				DOUBLE,
    Piano				DOUBLE,
    Dispersione			DOUBLE,
    PRIMARY KEY(IDStanza)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ==================== --
-- 	   PuntoAccesso     --
-- ==================== --
DROP TABLE IF EXISTS PuntoAccesso;
CREATE TABLE PuntoAccesso (
	CodiceAccesso		INT NOT NULL AUTO_INCREMENT,
    Tipologia			VARCHAR(50) NOT NULL,
							CHECK(Tipologia IN('Porta', 'Finestra', 'Portafinestra')),
    PuntoCardinale		VARCHAR(4) NOT NULL, 
							CHECK(PuntoCardinale IN('Nord', 'West', 'East', 'Sud')),
    PRIMARY KEY(CodiceAccesso)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ==================== --
-- 	   Collegamento     --
-- ==================== --
DROP TABLE IF EXISTS Collegamento;
CREATE TABLE Collegamento (
	CodiceAccesso		INT NOT NULL,
	IDStanza			INT NOT NULL,
    PRIMARY KEY(CodiceAccesso, IDStanza),
    
	FOREIGN KEY(CodiceAccesso) REFERENCES PuntoAccesso(CodiceAccesso),
	FOREIGN KEY(IDStanza) REFERENCES Stanza(IDStanza)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ========================= --
-- 	  RegistroInterazioni    --
-- ========================= --
DROP TABLE IF EXISTS RegistroInterazioni;
CREATE TABLE RegistroInterazioni (
	Inizio				DATETIME NOT NULL,
    Dispositivo			INT NOT NULL,
    Account				VARCHAR(10) NOT NULL, 
	Fine 				DATETIME,
							CHECK(Fine > Inizio),
	Regolazione			INT,
    Differita			VARCHAR(2) NOT NULL DEFAULT 'No',
							CHECK(Differita IN('Si','No')),
	Preleva				VARCHAR(2) NOT NULL DEFAULT 'No',
							CHECK(Preleva IN('Si','No')),
    PRIMARY KEY(Inizio, Dispositivo),
    
    FOREIGN KEY(Dispositivo) REFERENCES Dispositivo(CodiceDispositivo),
    FOREIGN KEY(Account) REFERENCES Account(Nickname)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================= --
-- 	  Dispositivo    --
-- ================= --
DROP TABLE IF EXISTS Dispositivo;
CREATE TABLE Dispositivo (
	CodiceDispositivo	INT NOT NULL AUTO_INCREMENT,
    Nome				VARCHAR(50), 
	Tipo 				VARCHAR(9),
							CHECK(Tipo IN ('Fisso', 'Variabile', 'ACiclo')),
	Potenza				DOUBLE,
    FattorePotenza		DOUBLE,
    RegolazioneMax		INT,
    Stanza				INT NOT NULL,
    PRIMARY KEY(CodiceDispositivo),
    
    FOREIGN KEY(Stanza) REFERENCES Stanza(IDStanza)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================= --
-- 	   Programma     --
-- ================= --
DROP TABLE IF EXISTS Programma;
CREATE TABLE Programma (
	CodiceProgramma		INT NOT NULL AUTO_INCREMENT,
    Durata				INT NOT NULL,
							CHECK(Durata>0),
    PotenzaMedia		DOUBLE NOT NULL,
							CHECK(PotenzaMedia>0),
	Dispositivo			INT NOT NULL,
    PRIMARY KEY(CodiceProgramma),
    
    FOREIGN KEY(Dispositivo) REFERENCES Dispositivo(CodiceDispositivo)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================== --
-- 	   Avviamento     --
-- ================== --
DROP TABLE IF EXISTS Avviamento;
CREATE TABLE Avviamento (
	CodiceProgramma		INT NOT NULL AUTO_INCREMENT,
	Dispositivo			INT NOT NULL,
    Inizio				DATETIME NOT NULL,
    PRIMARY KEY(CodiceProgramma, Dispositivo, Inizio),
    
    FOREIGN KEY(CodiceProgramma) REFERENCES Programma(CodiceProgramma),
    FOREIGN KEY(Dispositivo, Inizio) REFERENCES RegistroInterazioni(Dispositivo, Inizio)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ========================= --
-- 	  RegistroTemperatura    --
-- ========================= --
DROP TABLE IF EXISTS RegistroTemperatura;
CREATE TABLE RegistroTemperatura (
	Timestamp			DATETIME NOT NULL,
    Stanza				INT NOT NULL,
    Temperatura			INT NOT NULL, 
    PRIMARY KEY(Timestamp, Stanza),
    
    FOREIGN KEY(Stanza) REFERENCES Stanza(IDStanza)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- =========================== --
-- 	  ElementoIlluminazione    --
-- =========================== --
DROP TABLE IF EXISTS ElementoIlluminazione;
CREATE TABLE ElementoIlluminazione (
	Dispositivo			INT NOT NULL,
    Regolabile			VARCHAR(2) NOT NULL,
							CHECK(Regolabile IN('Si','No')),
    TempMinima			INT NOT NULL, 
    TempMassima			INT NOT NULL,
							CHECK(TempMinima <= TempMassima),	
    PRIMARY KEY(Dispositivo),
    
    FOREIGN KEY(Dispositivo) REFERENCES Dispositivo(CodiceDispositivo)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ============================ --
-- 	  ElementoCondizionamento   --
-- ============================ --
DROP TABLE IF EXISTS ElementoCondizionamento;
CREATE TABLE ElementoCondizionamento (
	Dispositivo			INT NOT NULL,
    PotRiscaldamento	DOUBLE NOT NULL,
							CHECK(PotRiscaldamento>0),
    TminRiscaldamento	INT NOT NULL, 
    TmaxRiscaldamento	INT NOT NULL,
							CHECK(TminRiscaldamento < TmaxRiscaldamento),	
	EER					INT NOT NULL,
    COP					INT NOT NULL,
    PRIMARY KEY(Dispositivo),
    
    FOREIGN KEY(Dispositivo) REFERENCES Dispositivo(CodiceDispositivo)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================== --
-- 	  RegistroLuci    --
-- ================== --
DROP TABLE IF EXISTS RegistroLuci;
CREATE TABLE RegistroLuci (
	Inizio				DATETIME NOT NULL,
	Dispositivo			INT NOT NULL,
    TempColore			INT NOT NULL,
    Intensita			INT NOT NULL,
							CHECK(Intensita BETWEEN 1 AND 100),
    PRIMARY KEY(Inizio, Dispositivo),
    
    FOREIGN KEY(Inizio, Dispositivo) REFERENCES RegistroInterazioni(Inizio, Dispositivo)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- =================== --
-- 	  RegistroClima    --
-- =================== --
DROP TABLE IF EXISTS RegistroClima;
CREATE TABLE RegistroClima (
	Inizio				DATETIME NOT NULL,
	Dispositivo			INT NOT NULL,
    Temperatura			INT NOT NULL, 
    Umidita				INT NOT NULL,
							CHECK(Umidita BETWEEN 0 AND 100),
	TempIniziale		INT,
    ArrivoTemp			DATETIME,
    PRIMARY KEY(Inizio, Dispositivo),
    
    FOREIGN KEY(Inizio, Dispositivo) REFERENCES RegistroInterazioni(Inizio, Dispositivo)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================ --
-- 	  Ricorrente    --
-- ================ --
DROP TABLE IF EXISTS Ricorrente;
CREATE TABLE Ricorrente (
	Inizio				DATETIME NOT NULL,
	Dispositivo			INT NOT NULL,
	CodiceRicorrenza	INT NOT NULL,
    PRIMARY KEY(Inizio, Dispositivo, CodiceRicorrenza),
    
    FOREIGN KEY(Inizio, Dispositivo) REFERENCES RegistroClima(Inizio, Dispositivo),
    FOREIGN KEY(CodiceRicorrenza) REFERENCES Ricorrenza(CodiceRicorrenza)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================ --
-- 	  Ricorrenza    --
-- ================ --
DROP TABLE IF EXISTS Ricorrenza;
CREATE TABLE Ricorrenza (
	CodiceRicorrenza	INT NOT NULL AUTO_INCREMENT,
	GiornoSettimanale   INT,
							CHECK(GiornoSettimanale BETWEEN 0 AND 7),
	GiornoMensile		INT,
							CHECK(GiornoMensile BETWEEN 1 AND 31),
    Temperatura			INT NOT NULL, 
    Umidità				INT NOT NULL,
							CHECK(Umidità BETWEEN 0 AND 100),
    PRIMARY KEY(CodiceRicorrenza)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ============= --
-- 	  Setting    --
-- ============= --
DROP TABLE IF EXISTS Setting;
CREATE TABLE Setting (
	Inizio				DATETIME NOT NULL,
	Dispositivo			INT NOT NULL,
	CodiceImpostazione	INT NOT NULL,
    PRIMARY KEY(Inizio, Dispositivo, CodiceImpostazione),
    
    FOREIGN KEY(Inizio, Dispositivo) REFERENCES RegistroLuci(Inizio, Dispositivo),
    FOREIGN KEY(CodiceImpostazione) REFERENCES ImpostazioneLuci(CodiceImpostazione)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ====================== --
-- 	  ImpostazioneLuci    --
-- ====================== --
DROP TABLE IF EXISTS ImpostazioneLuci;
CREATE TABLE ImpostazioneLuci (
	CodiceImpostazione	INT NOT NULL AUTO_INCREMENT,
    Intensita			INT NOT NULL, 
							CHECK(Intensita BETWEEN 0 AND 100),
    TempColore			INT NOT NULL,
	PRIMARY KEY(CodiceImpostazione)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================== --
-- 	  Suggerimento    --
-- ================== --
DROP TABLE IF EXISTS Suggerimento;
CREATE TABLE Suggerimento (
	Timestamp			DATETIME NOT NULL,
	Dispositivo			INT NOT NULL,
	Account				VARCHAR(10) NOT NULL,
    Scelta				VARCHAR(2) NOT NULL,
							CHECK(Scelta IN('Si','No')),
    PRIMARY KEY(Timestamp, Dispositivo),
    
    FOREIGN KEY(Dispositivo) REFERENCES Dispositivo(CodiceDispositivo),
    FOREIGN KEY(Account) REFERENCES Account(Nickname)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ============== --
-- 	  Prelievo    --
-- ============== --
DROP TABLE IF EXISTS Prelievo;
CREATE TABLE Prelievo (
	Dispositivo			INT NOT NULL,
    Inizio				DATETIME NOT NULL,
	Timestamp			DATETIME NOT NULL,
    PRIMARY KEY(Dispositivo, Inizio, Timestamp),
    
    FOREIGN KEY(Dispositivo, Inizio) REFERENCES RegistroInterazioni(Dispositivo, Inizio),
    FOREIGN KEY(Timestamp) REFERENCES SorgenteRinnovabile(Timestamp)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ========================= --
-- 	  SorgenteRinnovabile    --
-- ========================= --
DROP TABLE IF EXISTS SorgenteRinnovabile;
CREATE TABLE SorgenteRinnovabile (
	Timestamp			DATETIME NOT NULL,
    Potenza 			DOUBLE NOT NULL,
							CHECK(Potenza>=0),
    PRIMARY KEY(Timestamp)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ===================== --
-- 	  UtilizzoEnergia    --
-- ===================== --
DROP TABLE IF EXISTS UtilizzoEnergia;
CREATE TABLE UtilizzoEnergia (
	Timestamp			DATETIME NOT NULL,
    FasciaOraria		INT NOT NULL,
    PRIMARY KEY(Timestamp, FasciaOraria),
    
    FOREIGN KEY(Timestamp) REFERENCES SorgenteRinnovabile(Timestamp),
    FOREIGN KEY(FasciaOraria) REFERENCES FasciaOrariaUtente(Inizio)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ======================== --
-- 	  FasciaOrariaUtente    --
-- ======================== --
DROP TABLE IF EXISTS FasciaOrariaUtente;
CREATE TABLE FasciaOrariaUtente (
	Inizio			INT NOT NULL,
						CHECK(Inizio BETWEEN 0 AND 23),
    Fine 			INT NOT NULL,
						CHECK(FINE BETWEEN 1 AND 24),
						CHECK(Fine > Inizio),
    Uso				VARCHAR(2) NOT NULL,
						CHECK(Uso IN('Si','No')),
    PRIMARY KEY(Inizio)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- =============== --
-- 	  Contratto    --
-- =============== --
DROP TABLE IF EXISTS Contratto;
CREATE TABLE Contratto (
	Inizio			DATETIME NOT NULL,
    Fine 			DATETIME,
						CHECK(Fine > Inizio),
	F1				DOUBLE NOT NULL,
	F2				DOUBLE NOT NULL,
	F3				DOUBLE NOT NULL,
    kWMassimi		DOUBLE NOT NULL,
	Utente	 		VARCHAR(16) NOT NULL,
    PRIMARY KEY(Inizio),
    
    FOREIGN KEY(Utente) REFERENCES Utente(CodFiscale)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;
SET FOREIGN_KEY_CHECKS = 1;

-- ========================================================== --
-- 				VINCOLI GENERICI AGGIUNTIVI				      --
-- ========================================================== --

-- In Collegamento, lo stesso punto di accesso può collegare al massimo due stanze
DROP TRIGGER IF EXISTS ControlloCollegamento;
DELIMITER $$
CREATE TRIGGER ControlloCollegamento
BEFORE INSERT ON Collegamento
FOR EACH ROW
BEGIN

	DECLARE num_stanze_collegamento INT;
    SELECT COUNT(*) INTO num_stanze_collegamento
    FROM Collegamento
    WHERE CodiceAccesso = NEW.CodiceAccesso
    GROUP BY CodiceAccesso;
    
	IF num_stanze_collegamento = 2 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Questo punto di accesso collega già due stanze';
    END IF;
END $$
DELIMITER ;

-- In RegistroInterazioni Inizio deve essere maggiore o uguale a Fine dell'operazione precedente

DROP TRIGGER IF EXISTS ControlloDate;
DELIMITER $$
CREATE TRIGGER ControlloDate
BEFORE INSERT ON RegistroInterazioni
FOR EACH ROW
BEGIN

	IF NEW.Inizio < (
			SELECT RI.Fine
            FROM RegistroInterazioni RI
            WHERE RI.Dispositivo = NEW.Dispositivo
            ORDER BY RI.Fine DESC
            LIMIT 1
    )
    THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Questo dispositivo è già in uso';
    END IF;
	
END $$
DELIMITER ;

-- Per ogni inserimento di temperatura esterna, bisogna guardare che i climatizzatori in uso verifichino
-- la condizione: Tmin <= Testerna <= Tmax
/* disabilitato perchè sennò il popolamento del registrotemperatura è troppo lento
DROP TRIGGER IF EXISTS ControlloTemperature;
DELIMITER $$
CREATE TRIGGER ControlloTemperature
AFTER INSERT ON RegistroTemperatura
FOR EACH ROW
BEGIN
	DECLARE temp_prec INT;
    DECLARE timestamp_prec DATETIME;
    
    -- se la temperatura inserita è esterna (codice 1):
	IF NEW.Stanza = 1
    THEN     
    	-- prendo la temperatura dell'intervallo precedente
		SELECT RT.Temperatura, RT.Timestamp into temp_prec, timestamp_prec
		FROM RegistroTemperatura RT
        WHERE stanza = 1 AND RT.Timestamp <> NEW.Timestamp
		ORDER BY RT.Timestamp DESC
        LIMIT 1;
        
        IF temp_prec IS NOT NULL THEN 
		-- elimina le impostazioni che sono state inserite nei 30 minuti prima anche se non potevano essere inserite
        DELETE RI
        FROM RegistroInterazioni RI 
             NATURAL JOIN
			 ElementoCondizionamento EC
        WHERE (RI.Inizio >= timestamp_prec AND RI.Inizio < NEW.Timestamp)
			  AND temp_prec NOT BETWEEN EC.TminRiscaldamento AND EC.TmaxRiscaldamento;
              
		-- aggiorna le impostazioni che finiscono nei 30 minuti successivi, anticipando la fine al timestamp nuovo
		UPDATE RegistroInterazioni RI
		SET RI.Fine = NEW.Timestamp
        WHERE RI.Dispositivo IN (
								 SELECT RC.Dispositivo
                                 FROM RegistroClima RC
									  NATURAL JOIN
                                      ElementoCondizionamento EC
                                 WHERE (RC.Inizio >= NEW.Timestamp AND RC.Inizio < NEW.Timestamp + INTERVAL 30 MINUTE)
									   AND NEW.Temperatura NOT BETWEEN EC.TminRiscaldamento AND EC.TmaxRiscaldamento);
		END IF;
    END IF;
	
END $$
DELIMITER ;
*/
-- Un elemento di illuminazione deve essere di tipo 'Fisso' e non essere un condizionatore 

DROP TRIGGER IF EXISTS ControlloLuci;
DELIMITER $$
CREATE TRIGGER ControlloLuci
BEFORE INSERT ON ElementoIlluminazione
FOR EACH ROW
BEGIN
 
	IF NEW.Dispositivo IN (SELECT Dispositivo
							  FROM ElementoCondizionamento) 
    THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Questo dispositivo è un condizionatore.';
        
    ELSEIF NEW.Dispositivo NOT IN (SELECT CodiceDispositivo
								   FROM Dispositivo
                                   WHERE Tipo = 'Fisso') 
	THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Questo dispositivo non è di tipo fisso.';
	END IF;
 
END $$
DELIMITER ;

-- Un elemento di condizionamento deve essere di tipo 'Fisso' e non essere una luce

DROP TRIGGER IF EXISTS ControlloCondizionatori;
DELIMITER $$
CREATE TRIGGER ControlloCondizionatori
BEFORE INSERT ON ElementoCondizionamento
FOR EACH ROW
BEGIN
 
	IF NEW.Dispositivo IN (SELECT Dispositivo
							  FROM ElementoIlluminazione) 
    THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Questo dispositivo è una luce.';
        
    ELSEIF NEW.Dispositivo NOT IN (SELECT CodiceDispositivo
								   FROM Dispositivo
                                   WHERE Tipo = 'Fisso') 
	THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Questo dispositivo non è di tipo fisso.';
	END IF;
 
END $$
DELIMITER ;


