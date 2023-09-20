USE smart_home;
-- ================================================================================ --
--                                   OPERAZIONE 1                                   --
-- ================================================================================ --
DROP PROCEDURE IF EXISTS InsightDispositivo;
DELIMITER $$
CREATE PROCEDURE InsightDispositivo(IN _dispositivo INT, IN _mese INT)
BEGIN
    -- creo la tabella di output
	DROP TEMPORARY TABLE IF EXISTS Insight;
    CREATE TEMPORARY TABLE Insight(
		Account					VARCHAR(10) NOT NULL,
        PercentualeUtilizzo		INT NOT NULL
    );

    INSERT INTO Insight
	WITH InterazioniMese AS
	(
		SELECT *
		FROM RegistroInterazioni
		WHERE Dispositivo = _dispositivo
			  AND MONTH(Inizio) = _mese)
	SELECT	Account, 
			 COUNT(*)/(SELECT COUNT(*)
					   FROM InterazioniMese) * 100	-- percentuale utilizzo
	FROM InterazioniMese
	GROUP BY Account;
END $$
DELIMITER ;

-- ================================================================================ --
--                                   OPERAZIONE 2                                   --
-- ================================================================================ --
DROP PROCEDURE IF EXISTS EnergiaProdottaUsata;
DELIMITER $$
CREATE PROCEDURE EnergiaProdottaUsata(IN _inizio DATE, IN _fine DATE, OUT _energia_usata DOUBLE)
BEGIN
	-- Inizio non può essere maggiore di fine
	IF  _inizio > _fine
	THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Fine deve essere maggiore o uguale a Inizio';
    END IF;
    -- FINE CONTROLLI
    WITH InterazioniTarget AS
    (
		SELECT *, TIMESTAMPDIFF(HOUR, RI.Inizio, RI.Fine) AS Durata
        FROM RegistroInterazioni RI
			 INNER JOIN
			 Dispositivo D ON RI.Dispositivo = D.CodiceDispositivo
		WHERE RI.Inizio BETWEEN _inizio AND _fine 
			  AND RI.Preleva = 'Si'
              AND D.CodiceDispositivo NOT IN (SELECT Dispositivo FROM ElementoCondizionamento)
    )
    SELECT SUM(EUD.ConsumoInterazioni) INTO _energia_usata
    FROM (	SELECT IF(IT.Tipo = 'Variabile', IT.Regolazione * IT.FattorePotenza * IT.Durata,
					  IF(IT.Tipo = 'ACiclo', P.Durata * P.PotenzaMedia,
						 IT.Potenza * IT.Durata)) AS ConsumoInterazioni
			FROM InterazioniTarget IT
				 NATURAL LEFT OUTER JOIN
				 Avviamento A
                 NATURAL JOIN
                 Programma P
		 ) AS EUD;
END $$
DELIMITER ;

-- ================================================================================ --
--                                   OPERAZIONE 3                                   --
-- ================================================================================ --
DROP PROCEDURE IF EXISTS InserimentoImpostazioneClima;
DELIMITER $$
CREATE PROCEDURE InserimentoImpostazioneClima(IN _dispositivo INT, IN _account VARCHAR(10), IN _inizio DATETIME, IN _fine DATETIME, IN _temperatura INT, IN _umidita INT)
BEGIN
	-- la temperatura non può essere uguale a quella attuale interna della stanza
    DECLARE ultima_temp INT;
    SELECT FIRST_VALUE(RT.Temperatura) OVER(ORDER BY RT.Timestamp DESC) INTO ultima_temp
    FROM RegistroTemperatura RT
		 INNER JOIN
         Dispositivo D ON RT.Stanza = D.Stanza
	WHERE D.CodiceDispositivo = _dispositivo;
    IF ultima_temp = _temperatura 
	THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Non puoi impostare una temperatura già presente';
    END IF; 
    
	INSERT INTO RegistroInterazioni(Inizio, Dispositivo, Account, Fine, Regolazione)
	VALUES	(_inizio, _dispositivo, _account, _fine, null);
    
    INSERT INTO RegistroClima(Inizio, Dispositivo, Temperatura, Umidita)
	VALUES	(_inizio, _dispositivo, _temperatura, _umidita);
END $$
DELIMITER ;

-- ================================================================================ --
--                                   OPERAZIONE 4                                   --
-- ================================================================================ --
DROP PROCEDURE IF EXISTS UsoEcosostenibile;
DELIMITER $$
CREATE PROCEDURE UsoEcosostenibile(IN _dispositivo INT, IN _mese INT, OUT is_eco_ BOOLEAN)
BEGIN
	DECLARE percentuale_prelievo INT;
    -- controllo che il dispositivo non sia un condizionatore
    IF _dispositivo IN (SELECT Dispositivo FROM ElementoCondizionamento) THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Il dispositivo non può essere un condizionatore';
	END IF;
    
	WITH InterazioniTarget AS
    (
		SELECT *
        FROM RegistroInterazioni RI
			 INNER JOIN
             Dispositivo D ON RI.Dispositivo = D.CodiceDispositivo
        WHERE RI.Dispositivo = _dispositivo
			  AND MONTH(RI.Inizio) = _mese 
    ),
    EnergiaPreleva AS
    (
		SELECT SUM(IF(IT.Tipo = 'Fisso', IT.Potenza, 
					  IF(IT.Tipo = 'Variabile', IT.Regolazione*IT.FattorePotenza,
						 P.PotenzaMedia)) * TIMESTAMPDIFF(HOUR, IT.Inizio, IT.Fine)) AS Consumo, IT.Preleva
		FROM InterazioniTarget IT
			 NATURAL LEFT OUTER JOIN 
			 Avviamento A 
			 NATURAL JOIN
			 Programma P 
		GROUP BY IT.Preleva
    )
    -- calcolo la percentuale di prelievo
	SELECT Consumo/(SELECT SUM(Consumo)
					FROM EnergiaPreleva) * 100 INTO percentuale_prelievo
    FROM EnergiaPreleva
    WHERE Preleva = 'Si';
    
    -- se è maggiore del 50%, è stato usato in maniera ecosostenibile
	IF percentuale_prelievo > 50
    THEN
		SET is_eco_ = true;
	ELSE
		SET is_eco_ = false;
	END IF;
END $$
DELIMITER ;
-- ================================================================================ --
--                                   OPERAZIONE 5                                   --
-- ================================================================================ --
DROP PROCEDURE IF EXISTS ClassificaInterazioni;
DELIMITER $$
CREATE PROCEDURE ClassificaInterazioni()
BEGIN
    -- creo la tabella di output
	DROP TEMPORARY TABLE IF EXISTS Classifica;
    CREATE TEMPORARY TABLE Classifica(
		Account					VARCHAR(10) NOT NULL,
        NumInterazioni			INT NOT NULL,
        Posizione				INT NOT NULL
    );

    INSERT INTO Classifica
	SELECT Nickname, NumInterazioni, RANK() OVER(ORDER BY NumInterazioni DESC)
    FROM Account;
    
    SELECT * 
    FROM Classifica;
END $$
DELIMITER ;

-- TRIGGER AGGIORNAMENTO RIDONDANZA NumInterazioni
DROP TRIGGER IF EXISTS AggiornamentoNumInterazioni;
DELIMITER $$
CREATE TRIGGER AggiornamentoNumInterazioni
AFTER INSERT ON RegistroInterazioni
FOR EACH ROW
BEGIN

	UPDATE Account
    SET NumInterazioni = NumInterazioni + 1
    WHERE Nickname = NEW.Account;
 
END $$
DELIMITER ;

-- ================================================================================ --
--                                   OPERAZIONE 6                                   --
-- ================================================================================ --
DROP PROCEDURE IF EXISTS ConsumoCondizionatoreGiorno;
DELIMITER $$
CREATE PROCEDURE ConsumoCondizionatoreGiorno(IN _dispositivo INT, IN _data DATE, OUT consumo_ DOUBLE)
BEGIN
	DECLARE inizio DATETIME;
    DECLARE fine DATETIME;
    DECLARE stanza INT;
    DECLARE dispersione INT;
    DECLARE superficie_esterno DOUBLE;
    DECLARE temp_impostata INT;
    DECLARE temp_iniziale INT;
    DECLARE ora_arrivo_temp INT;
    DECLARE temp_ext_avg DOUBLE;
    DECLARE consumo_mantenimento DOUBLE;
    DECLARE pot_raff DOUBLE;
    DECLARE pot_risc DOUBLE;
    DECLARE EER DOUBLE;
    DECLARE COP DOUBLE;
	DECLARE finish INT DEFAULT 0;
    -- dichiaro il cursore e l'handler
	DECLARE interaction_cursor CURSOR FOR (SELECT RI.Inizio, RI.Fine, RC.TempIniziale, RC.ArrivoTemp, RC.Temperatura
										   FROM RegistroInterazioni RI
												INNER JOIN
                                                RegistroClima RC
                                           WHERE RI.Dispositivo = _dispositivo
												 AND DAY(RI.Inizio) = DAY(_data));
	DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET finish = 1;
    -- SETTING VARIABILI COMUNI A TUTTE LE INTERAZIONI
    -- setto la stanza, la sua superficie, la sua dispersione, la potenza di raffreddamento, la potenza di riscaldamento
    SELECT S.Dispersione, S.IDStanza, D.Potenza, EC.PotRiscaldamento, EC.EER, EC.COP, 
		   (S.Larghezza+S.Lunghezza)*S.Altezza INTO dispersione, stanza, pot_raff, pot_risc, EER, COP, superficie_esterno
    FROM Dispositivo D
		 INNER JOIN
         Stanza S ON D.Stanza = S.IDStanza
         INNER JOIN
         ElementoCondizionamento EC ON EC.Dispositivo = D.CodiceDispositivo
	 WHERE D.CodiceDispositivo = _dispositivo;
     
    -- APRO IL CURSORE
    OPEN interaction_cursor;
    loop_label: LOOP 
		IF finish = 1 THEN
			LEAVE loop_label;
		END IF;
        
		FETCH interaction_cursor INTO inizio, fine, temp_iniziale, ora_arrivo_temp, temp_impostata;
		
        -- si salva la temperatura esterna media, tra ora_arrivo_temp e fine
		SELECT AVG(RT3.Temperatura) INTO temp_ext_avg
        FROM RegistroTemperatura RT3
        WHERE RT3.Stanza = 1	-- esterno
              AND RT3.Timestamp BETWEEN ora_arrivo_temp AND fine;
        
		-- se riscaldiamo:
		IF temp_impostata > temp_iniziale THEN
			SET consumo_ = consumo_ + pot_risc * TIMESTAMPDIFF(HOUR, inizio, ora_arrivo_temp);
			-- calcoliamo il consumo per mantenere la temperatura, con il COP
			SET consumo_mantenimento = ((temp_impostata - temp_ext_avg) * (dispersione/1000) * superficie_esterno * (TIMESTAMPDIFF(HOUR, ora_arrivo_temp, fine))) / COP;
		-- se raffreddiamo:
		ELSEIF temp_impostata < temp_iniziale THEN
			SET consumo_ = consumo_ + pot_raff * TIMESTAMPDIFF(HOUR, inizio, ora_arrivo_temp);
			-- calcoliamo il consumo per mantenere la temperatura, con l'EER
			SET consumo_mantenimento = ((temp_impostata - temp_ext_avg) * (dispersione/1000) * superficie_esterno * (TIMESTAMPDIFF(HOUR, ora_arrivo_temp, fine))) / EER;
		END IF;
        
		SET consumo_ = consumo_ + consumo_mantenimento;
	END LOOP;
    CLOSE interaction_cursor;
END $$
DELIMITER ;

-- EVENT DI AGGIORNAMENTO RIDONDANZA
DROP EVENT IF EXISTS AggiornamentoRegistroClima;
DELIMITER $$
CREATE EVENT AggiornamentoRegistroClima
ON SCHEDULE EVERY 1 DAY
STARTS CONCAT(CURRENT_DATE()+INTERVAL 1 DAY, ' 00:00:00')
DO
BEGIN
	DECLARE inizio DATETIME;
    DECLARE fine DATETIME;
	DECLARE stanza INT;
    DECLARE ora_arrivo_temp DATETIME;
    DECLARE temp_iniziale INT;
    
	DECLARE finito INT DEFAULT 0;
    -- dichiaro cursore e handler
	DECLARE cursore_clima CURSOR FOR (SELECT RI.Inizio, RI.Fine, S.IDStanza
									  FROM RegistroClima RC
										   INNER JOIN 
                                           RegistroInterazioni RI
                                           INNER JOIN 
                                           Stanza S
									  WHERE DAY(RC.Inizio) = DAY(CURRENT_DATE()) - 1);
	DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET finito = 1;
    
    OPEN cursore_clima;
    loop_label: LOOP
		IF finish = 1 THEN
			LEAVE loop_label;
		END IF;
        
		FETCH cursore_clima INTO inizio, fine, stanza;
        
        -- prendo la temperatura interna all'inizio dell'interazione
		SELECT RT.Temperatura INTO temp_iniziale
		FROM RegistroTemperatura RT
		WHERE RT.Stanza = stanza
			  AND inizio - INTERVAL 30 MINUTE >= RT.Timestamp
		LIMIT 1;
        -- prendo l'ora alla quale si raggiunge la temperatura desiderata
		SELECT RT2.Timestamp INTO ora_arrivo_temp
        FROM RegistroTemperatura RT2
        WHERE RT2.Stanza = stanza
			  AND RT2.Temperatura = temp_impostata
              AND RT2.Timestamp BETWEEN inizio AND fine
		LIMIT 1;
		-- inserisco le ridondanze
		UPDATE Account
		SET TempIniziale = temp_iniziale, ArrivoTemp = ora_arrivo_temp
		WHERE Nickname = NEW.Account;
        
	END LOOP;
    CLOSE cursore_clima;
END $$
DELIMITER ;
-- ================================================================================ --
--                                   OPERAZIONE 7                                   --
-- ================================================================================ --
DROP PROCEDURE IF EXISTS AvvioImpostazioneLuciStanza;
DELIMITER $$
CREATE PROCEDURE AvvioImpostazioneLuciStanza(IN _stanza INT, IN _account VARCHAR(10), IN _inizio DATETIME, IN _fine DATETIME, IN _impostazione INT)
BEGIN
	DECLARE dispositivo INT;
	DECLARE temp_colore INT;
    DECLARE intensita INT;
    DECLARE regolabile VARCHAR(2);
    DECLARE temp_min INT;
    DECLARE temp_max INT;
	DECLARE ultima_temp INT;
    
	DECLARE finito INT DEFAULT 0;
    -- dichiaro cursore e handler
	DECLARE cursore_luci CURSOR FOR (SELECT D.CodiceDispositivo, EI.Regolabile, EI.TempMinima, EI.TempMassima
									 FROM Dispositivo D 
										  INNER JOIN
                                          ElementoIlluminazione EI ON D.CodiceDispositivo = EI.Dispositivo
									 WHERE D.Stanza = _stanza);
	DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET finito = 1;

    OPEN cursore_luci;
    loop_label: LOOP
		FETCH cursore_luci INTO dispositivo, regolabile, temp_min, temp_max;
		IF finito = 1 THEN
			LEAVE loop_label;
		END IF;
		
		-- prendo temperatura di colore e intensità dell'impostazione
		SELECT IL.TempColore, IL.Intensita INTO temp_colore, intensita
		FROM ImpostazioneLuci IL
		WHERE IL.CodiceImpostazione = _impostazione;
    
		INSERT INTO RegistroInterazioni(Inizio, Dispositivo, Account, Fine, Regolazione)
		VALUES	(_inizio, dispositivo, _account, _fine, null);
        
		-- se non è regolabile imposto al massimo
		IF regolabile = 'No' THEN
			SET intensita = 100;
		END IF;
        -- se la temp. di colore è fuori range si imposta quella più vicina
        IF temp_colore > temp_max THEN
			SET temp_colore = temp_max;
		ELSEIF temp_colore < temp_min THEN
			SET temp_colore = temp_min;
		END IF;
        
		INSERT INTO RegistroLuci(Inizio, Dispositivo, TempColore, Intensita)
		VALUES	(_inizio, dispositivo, temp_colore, intensita);
            
		INSERT INTO Setting(Inizio, Dispositivo, CodiceImpostazione)
		VALUES	(_inizio, dispositivo, _impostazione);
		
	END LOOP;
    CLOSE cursore_luci;
END $$
DELIMITER ;

-- ================================================================================ --
--                                   OPERAZIONE 8                                   --
-- ================================================================================ --
DROP PROCEDURE IF EXISTS RiepilogoProduzione;
DELIMITER $$
CREATE PROCEDURE RiepilogoProduzione(OUT produzione_ DOUBLE)
BEGIN
	-- sommo tutte le potenze * 15 minuti
	SELECT SUM(Potenza*0.25) INTO produzione_
    FROM SorgenteRinnovabile
    WHERE DAY(Timestamp) = DAY(CURRENT_DATE); 
END $$
DELIMITER ;


