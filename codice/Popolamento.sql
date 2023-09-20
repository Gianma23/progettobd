USE smart_home;
SET SESSION max_execution_time = 10000;
SET SQL_SAFE_UPDATES = 0;
-- ================================================================================ --
--                         Documento, utente e account                              --
-- ================================================================================ --       
INSERT INTO Documento(Numero, Tipologia, Scadenza, Ente)
VALUES	('123456', 'Carta di identità' , '2022-08-08', 'Comune di Roma'),
        ('654321', 'Carta di identità' , '2022-08-08', 'Comune di Lignano'),
        ('585786', 'Patente di guida' , '2022-08-08','Motorizzazione di Livorno'),
        ('258147', 'Passaporto', '2023-03-15', 'Questura di Milano'),
        ('258507', 'Patente di guida', '2023-01-01', 'Motorizzazione di Livorno');
        
INSERT INTO Utente(CodFiscale, Nome, Cognome, DataNascita, NumTelefono, Documento)
VALUES	('SCTLCA02H64H501V', 'Vittorio', 'Scotti', '2001-03-11', '3663452333', '123456'),
		('SCVHCA06H64H501V', 'Marco', 'Rossi', '1976-04-15', '3663452231', '654321'),
        ('SGGLCA02901H54CF', 'Francesco', 'Rossi', '1990-01-15', '3313452563', '585786'),
        ('NNPV2A02H64H5EFF', 'Anna', 'Rossi', '2001-03-11', '3421552133', '258147'),
        ('LCPNCA045HPI501V', 'Lucia', 'Pina', '1970-09-20', '3688413212', '258507');

INSERT INTO Account(Nickname, Password, DomandaSicurezza, RispostaSicurezza, DataIscrizione, Utente)
VALUES	('Scotti01', 'buonasera!', 'Il nome della tua prima ragazza?', 'Ludovica', '2021-06-11','SCTLCA02H64H501V' ),
		('Markus', '15041976', 'Il nome del tuo professore di ginnastica alle medie?', 'Pedro', '2021-06-09', 'SCVHCA06H64H501V'),
        ('Kekko', '15011990', 'Il nome della tua prima ragazza?', 'Lucia', '2021-07-01', 'SGGLCA02901H54CF'),
        ('AnnA_', 'password', 'Come si chiamava il tuo primo animale?', 'Bob', '2021-09-11', 'NNPV2A02H64H5EFF'),
        ('Lucy70', 'NonSoCosaMettere', 'Il nome del tuo primo ragazzo?', 'Gianmaria', '2021-05-23', 'LCPNCA045HPI501V');
        
-- ================================================================================ --
--                     Stanza, PuntoAccesso e Collegamenti                          --
-- ================================================================================ --       
INSERT INTO Stanza(Nome, Larghezza, Lunghezza, Altezza, Piano, Dispersione)
VALUES	('Esterno', null, null, null, null, null),
		('Salotto', 7, 4, 2.5, 0, 1.5),
		('Cucina', 4, 3, 2.5, 0, 0.8),
        ('Camera', 4, 3, 2.5, 1, 1.4),
        ('Camerina', 3, 2, 2.5, 1, 1.4),
        ('Bagno', 5.5, 4, 2.5, 0, 1.2),
        ('Corridoio', 5.5, 4, 2.5, 1, 1.3),
        ('Terrazzo', 5.5, 4, null, 1, null),
		('Corridoio terra', 5, 3, 2.5, 0, 1.1);
 
INSERT INTO PuntoAccesso(Tipologia, PuntoCardinale)
VALUES	-- piano terra
		('Porta', 'Sud'),
		('Porta', 'Sud'),
        ('Porta', 'Sud'),
        ('Porta', 'East'),
        ('Porta', 'West'),
        ('Finestra', 'East'),
		('Finestra', 'West'),
        ('Finestra', 'West'),
        ('Finestra', 'Sud'),
        -- piano 1
        ('Porta', 'Nord'),
        ('Porta', 'East'),
        ('Portafinestra', 'Nord'),
        ('Portafinestra', 'East'),
		('Finestra', 'West'),
        ('Finestra', 'East');
        
INSERT INTO Collegamento(CodiceAccesso, IDStanza)
VALUES	('1', '1'),
		('1', '2'),
		('2', '2'),
		('2', '9'),
        ('3', '2'),
        ('3', '3'),
        ('4', '9'),
        ('4', '6'),
        ('5', '9'),
        ('5', '3'),
        ('6', '2'),
        ('6', '1'),
		('7', '2'),
		('7', '1'),
        ('8', '3'),
        ('8', '1'),
        ('9', '6'),
        ('9', '1'),
        -- piano 1
        ('10', '7'),
        ('10', '4'),
        ('11', '7'),
        ('11', '5'),
        ('12', '4'),
        ('12', '8'),
        ('13', '5'),
        ('13', '8'),
		('14', '4'),
		('14', '1'),
        ('15', '5'),
        ('15', '1');


-- ================================================================================ --
--                       Dispositivi, luci e condizionatori                         --
-- ================================================================================ --               
INSERT INTO Dispositivo(Nome, Tipo, Potenza, FattorePotenza, RegolazioneMax, Stanza)
VALUES	('Luci sala', 'Fisso', 0.5, null, null, 1),
		('Luci cucina', 'Fisso', 0.4, null, null, 2),
        ('Luci camera', 'Fisso', 0.2, null, null, 3),
        ('Luci camerina', 'Fisso', 0.3, null, null, 4),
        ('Luci bagno', 'Fisso', 0.1, null, null, 5),
        ('Luci bagno2', 'Fisso', 0.1, null, null, 5),	-- 6
        ('Lavatrice', 'ACiclo', null, null, null, 5),
        ('Lavastoviglie', 'ACiclo', null, null, null, 5),
        ('Frigorifero', 'Fisso', 0.3, null, null, 2),
        ('Microonde', 'Fisso', 0.2, null, null, 2),
        ('Forno', 'Variabile', null, 1, 3, 2), 	-- 11
        ('Condizionatore camera', 'Fisso', 3.5, null, null, 3),
        ('Condizionatore camerina', 'Fisso', 3.0, null, null, 4),
        ('Frullatore', 'Variabile', null, 0.2, 3, 2),
        ('Tostapane', 'Variabile', null, 0.5, 3, 2),	-- 15
        ('Televisore', 'Fisso', 0.1, null, null, 1),
        ('Ventilatore sala', 'Variabile', null, 0.7, 3, 1),
        ('Ventilatore cucina', 'Variabile', null, 0.7, 3, 2);	-- 18
     
     
INSERT INTO ElementoCondizionamento(Dispositivo, PotRiscaldamento, TMinRiscaldamento, TMaxRiscaldamento, EER, COP)
VALUES	(12, 0.5, -18, 25, 2.5, 5),
		(13, 0.5, -20, 27, 3, 5);


INSERT INTO ElementoIlluminazione(Dispositivo, Regolabile, TempMinima, TempMassima)
VALUES	(1, 'Si', 3500, 3500),
		(2, 'Si', 3500, 3500),
        (3, 'No', 3500, 3500),
        (4, 'Si', 3500, 3500),
        (5, 'No', 3500, 3500),
        (6, 'Si', 3500, 3500);


INSERT INTO ImpostazioneLuci(Intensita, TempColore)	
VALUES	(50, 4000),
		(100, 3500),
        (30, 2500);
        
        
-- ================================================================================ --
--                                   Programma                                      --
-- ================================================================================ --       
INSERT INTO Programma(Durata, PotenzaMedia, Dispositivo)	-- durano tutti un'ora per semplicità
VALUES	(1, 1.5, 7),
		(1, 1.0, 7),
        (1, 1.5, 7),
        (1, 0.3, 8),
        (1, 0.5, 8),
        (1, 0.6, 8);


-- ================================================================================ --
--                        RegistroInterazioni, luci e clima                         --
-- ================================================================================ --
DROP PROCEDURE IF EXISTS popolamento_RegistroInterazioni;
DELIMITER $$
CREATE PROCEDURE popolamento_RegistroInterazioni(IN _inizio DATETIME, IN _fine DATETIME)
BEGIN
	DECLARE dispositivo INT;
    DECLARE tipo VARCHAR(9);
    DECLARE tempo DATETIME;
    DECLARE rand_nickname VARCHAR(10);
    DECLARE fine DATETIME;
    
	DECLARE finito INT DEFAULT 0;
	DECLARE cursore_disp CURSOR FOR (SELECT D.CodiceDispositivo, D.Tipo
									 FROM Dispositivo D
									 WHERE D.CodiceDispositivo NOT IN (SELECT EI.Dispositivo
																	   FROM ElementoIlluminazione EI)
										   AND D.CodiceDIspositivo NOT IN (SELECT EC.Dispositivo 
																		   FROM ElementoCondizionamento EC));
	DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET finito = 1;
    
    OPEN cursore_disp;
    loop_label: LOOP
		FETCH cursore_disp INTO dispositivo, tipo;
		IF finito = 1 THEN
			LEAVE loop_label;
		END IF;

		-- imposto il primo inizio alle 6 del mattino 
		SET tempo = CONCAT(DATE(_inizio), ' 06:00:00');
		-- per ogni dispositivo, che non sia luce o condizionatore, si popola da inizio a fine
		WHILE tempo <= _fine 
		DO	
			-- prendo un account a caso
			SELECT Nickname INTO rand_nickname
			FROM Account
			ORDER BY RAND()
            LIMIT 1;
            
			-- imposto una fine random tra 10 e 20 minuti dopo l'inizio
			SET fine = tempo + INTERVAL (10 + RAND()*(60-10)) MINUTE;
					
			IF Tipo = 'Fisso' THEN
				INSERT INTO RegistroInterazioni(Inizio, Dispositivo, Account, Fine, Regolazione)
				VALUES (tempo, dispositivo, rand_nickname, fine, null);
			ELSEIF Tipo = 'Variabile' THEN 
				INSERT INTO RegistroInterazioni(Inizio, Dispositivo, Account, Fine, Regolazione)
				VALUES (tempo, dispositivo, rand_nickname, fine, 1+RAND()*2);
			ELSEIF Tipo = 'ACiclo' THEN
				SET fine = tempo + INTERVAL 1 HOUR;
				INSERT INTO RegistroInterazioni(Inizio, Dispositivo, Account, Fine, Regolazione)
				VALUES (tempo, dispositivo, rand_nickname, fine, null);
                IF dispositivo = 7 THEN
					INSERT INTO Avviamento(CodiceProgramma, Dispositivo, Inizio)
					VALUES (1+RAND()*2, dispositivo, tempo);
                ELSE 
					INSERT INTO Avviamento(CodiceProgramma, Dispositivo, Inizio)
					VALUES (4+RAND()*2, dispositivo, tempo);
				END IF;
			END IF;
			
            -- aggiornamento prossimo inizio
            IF DAY(tempo) < DAY(fine) THEN
				SET tempo = CONCAT(DATE(fine), ' 06:00:00');
			END IF;
			SET tempo = fine + INTERVAL RAND()*6 HOUR;
            IF DAY(tempo) > DAY(fine) THEN
				SET tempo = CONCAT(DATE(tempo), ' 06:00:00');
            END IF;
		END WHILE;
    END LOOP;
    CLOSE cursore_disp;
END $$
DELIMITER ;
-- popolo tutto ottobre e elimino la procedure, serve solo per popolare
CALL popolamento_RegistroInterazioni('2021-10-01 00:00:00', '2021-10-31 00:00:00');
DROP PROCEDURE popolamento_RegistroInterazioni;


DROP PROCEDURE IF EXISTS popolamento_luci;
DELIMITER $$
CREATE PROCEDURE popolamento_luci(_inizio DATETIME, _fine DATETIME)
BEGIN
	DECLARE stanza INT;
    DECLARE tempo DATETIME;
    DECLARE rand_nickname VARCHAR(10);
    DECLARE fine DATETIME;
    DECLARE rand_impostazione INT;
    
	DECLARE finito INT DEFAULT 0;
    -- dichiaro cursore e handler
	DECLARE cursore_stanza CURSOR FOR (SELECT DISTINCT S.IDStanza
									   FROM Stanza S
											INNER JOIN
                                            Dispositivo D ON D.Stanza = S.IDStanza
								  	   WHERE D.CodiceDispositivo IN (SELECT EI.Dispositivo
																	   FROM ElementoIlluminazione EI));
	DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET finito = 1;
    
    OPEN cursore_stanza;
    loop_label: LOOP
		FETCH cursore_stanza INTO stanza;
		IF finito = 1 THEN
			LEAVE loop_label;
		END IF;
        
		-- imposto il primo inizio alle 6 del mattino 
		SET tempo = CONCAT(DATE(_inizio), ' 06:00:00');
    
		-- per ogni stanza, si popola da inizio a fine
		WHILE tempo <= _fine 
		DO	
			-- prendo un account a caso
			SELECT Nickname INTO rand_nickname
			FROM Account
			ORDER BY RAND()
            LIMIT 1;
            -- prendo una impostazione luci a caso
			SELECT CodiceImpostazione INTO rand_impostazione
			FROM ImpostazioneLuci
			ORDER BY RAND()
            LIMIT 1;
            
			-- imposto una fine random tra 10 e 20 minuti dopo l'inizio
			SET fine = tempo + INTERVAL (20 + RAND()*(120-20)) MINUTE;

			CALL AvvioImpostazioneLuciStanza(stanza, rand_nickname, tempo, fine, rand_impostazione);
			
            -- aggiornamento prossimo inizio
            IF DAY(tempo) < DAY(fine) THEN
				SET tempo = CONCAT(DATE(fine), ' 06:00:00');
			END IF;
			SET tempo = fine + INTERVAL RAND()*6 HOUR;
            IF DAY(tempo) > DAY(fine) THEN
				SET tempo = CONCAT(DATE(tempo), ' 06:00:00');
            END IF;
		END WHILE;
    END LOOP;
    CLOSE cursore_stanza;
END $$
DELIMITER ;
-- popolo tutto ottobre e elimino la procedure, serve solo per popolare
CALL popolamento_luci('2021-10-01 00:00:00', '2021-10-31 00:00:00');
DROP PROCEDURE popolamento_luci;


DROP PROCEDURE IF EXISTS popolamento_condizionatori
DELIMITER $$
CREATE PROCEDURE popolamento_condizionatori(_inizio DATETIME, _fine DATETIME)
BEGIN
	DECLARE dispositivo INT;
    DECLARE tempo DATETIME;
    DECLARE rand_nickname VARCHAR(10);
    DECLARE fine DATETIME;
    
	DECLARE finito INT DEFAULT 0;
	DECLARE cursore_disp CURSOR FOR (SELECT EC.Dispositivo
									 FROM ElementoCondizionamento EC);
	DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET finito = 1;
    
    OPEN cursore_disp;
    loop_label: LOOP
		FETCH cursore_disp INTO dispositivo;
		IF finito = 1 THEN
			LEAVE loop_label;
		END IF;

		-- imposto il primo inizio alle 6 del mattino 
		SET tempo = CONCAT(DATE(_inizio), ' 06:00:00');
		-- per ogni dispositivo, che non sia luce o condizionatore, si popola da inizio a fine
		WHILE tempo <= _fine 
		DO	
			-- prendo un account a caso
			SELECT Nickname INTO rand_nickname
			FROM Account
			ORDER BY RAND()
            LIMIT 1;
            
			-- imposto una fine random tra 120 e 200 minuti dopo l'inizio
			SET fine = tempo + INTERVAL (120 + RAND()*(200-120)) MINUTE;
					
			CALL InserimentoImpostazioneClima(dispositivo, rand_nickname, tempo, fine, 20+RAND()*4, 50);
			
            -- aggiornamento prossimo inizio
            IF DAY(tempo) < DAY(fine) THEN
				SET tempo = CONCAT(DATE(fine), ' 06:00:00');
			END IF;
			SET tempo = fine + INTERVAL RAND()*6 HOUR;
            IF DAY(tempo) > DAY(fine) THEN
				SET tempo = CONCAT(DATE(tempo), ' 06:00:00');
            END IF;
		END WHILE;
    END LOOP;
    CLOSE cursore_disp;
END $$
DELIMITER ;
-- popolo tutto ottobre e elimino la procedure, serve solo per popolare
CALL popolamento_condizionatori('2021-10-01 00:00:00', '2021-10-31 00:00:00');
DROP PROCEDURE popolamento_condizionatori;


-- ================================================================================ --
--                            FasciaOrariaUtente                                    --
-- ================================================================================ --
INSERT INTO FasciaOrariaUtente(Inizio, Fine, Uso)
VALUES	(6, 12, 'No'),
		(12, 18, 'Si'),
        (18, 21, 'No');
        
        
-- ================================================================================ --
--                                  Contratto                                       --
-- ================================================================================ --
INSERT INTO Contratto(Inizio, Fine, F1, F2, F3, kWMassimi, Utente)
VALUES	('2018-06-10', '2019-01-01', 0.2, 0.2 , 0.2, 3.5, 'SCVHCA06H64H501V'),
		('2019-01-01', '2020-01-01', 0.2, 0.18 , 0.18, 4.5, 'SCVHCA06H64H501V'),
        ('2020-01-01', null, 0.4, 0.25 , 0, 6, 'LCPNCA045HPI501V');
       
       
-- ================================================================================ --
--                            SorgenteRinnovabile                                   --
-- ================================================================================ --
DROP PROCEDURE IF EXISTS popolamento_SorgenteRinnovabile;
DELIMITER $$
CREATE PROCEDURE popolamento_SorgenteRinnovabile(IN _inizio DATETIME, IN _fine DATETIME)
BEGIN
    DECLARE tempo DATETIME;
    DECLARE potenza DOUBLE;
    DECLARE ora_decimale DOUBLE;
    DECLARE fascia_oraria INT;
    
    SET tempo = _inizio;
    
	WHILE tempo <= _fine 
    DO	
		-- seleziono la fascia oraria 
		SELECT FOU.Inizio INTO fascia_oraria
		FROM FasciaOrariaUtente FOU
		WHERE HOUR(tempo) >= FOU.Inizio AND HOUR(tempo) < FOU.Fine;
        
		SET ora_decimale = HOUR(tempo) + MINUTE(tempo) / 60;
		SET potenza = ROUND(((13/SQRT(2*3.14*3)) * EXP(-((POW(ora_decimale-12, 2))/6))), 2);	-- varianza = 3 , mediana = 12
		
		INSERT INTO SorgenteRinnovabile(Timestamp, Potenza)
		VALUES (tempo, potenza);
        IF fascia_oraria IS NOT NULL THEN
			INSERT INTO UtilizzoEnergia(Timestamp, FasciaOraria)
			VALUES	(tempo, fascia_oraria);
        END IF;
        
		SET tempo = tempo + INTERVAL 15 MINUTE;
    END WHILE;
    
END $$
DELIMITER ;
-- popolo tutto ottobre e elimino la procedure, serve solo per popolare
CALL popolamento_SorgenteRinnovabile('2021-10-01 00:00:00', '2021-10-31 00:00:00');
DROP PROCEDURE popolamento_SorgenteRinnovabile;


-- ================================================================================ --
--                            RegistroTemperatura                                   --
-- ================================================================================ --
DROP PROCEDURE IF EXISTS popolamento_RegistroTemperatura;
DELIMITER $$
CREATE PROCEDURE popolamento_RegistroTemperatura(_inizio DATETIME, _fine DATETIME)
BEGIN
    DECLARE tempo DATETIME;
    DECLARE temperatura INT;
    DECLARE ora_decimale DOUBLE;
    DECLARE random_number INT;
    DECLARE stanza INT;
    
	DECLARE finito INT DEFAULT 0;
	DECLARE cursore_stanza CURSOR FOR (SELECT S.IDStanza
									   FROM Stanza S);
	DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET finito = 1;
    
    -- per ogni stanza, popolo da inizio a fine 
    OPEN cursore_stanza;
    loop_label: LOOP
		FETCH cursore_stanza INTO stanza;
		IF finito = 1 THEN
			LEAVE loop_label;
		END IF;
        
        SET tempo = _inizio;
		WHILE tempo <= _fine 
		DO	
			SET ora_decimale = HOUR(tempo) + MINUTE(tempo) / 60;
			
            SET temperatura = 18 + (16/SQRT(2*3.14*3)) * EXP(-((POW(ora_decimale-12, 2))/6));	-- varianza = 3 , mediana = 12
            
            IF stanza = 1 THEN
				SET temperatura = 14 + (16/SQRT(2*3.14*3)) * EXP(-((POW(ora_decimale-12, 2))/6));	-- varianza = 3 , mediana = 12
			ELSEIF stanza = 4 OR stanza = 5 THEN
				SET temperatura = (SELECT RC.Temperatura
								   FROM RegistroClima RC
                                   WHERE RC.Dispositivo = 12 OR RC.Dispositivo = 13 
										 AND RC.Inizio BETWEEN tempo AND tempo + INTERVAL 30 MINUTE
								   LIMIT 1);
			END IF;

			INSERT INTO RegistroTemperatura(Timestamp, Stanza, Temperatura)
			VALUES (tempo, stanza, temperatura);
            
			SET tempo = tempo + INTERVAL 30 MINUTE;
		END WHILE;
    END LOOP;
    CLOSE cursore_stanza;
END $$
DELIMITER ;
-- popolo tutto ottobre e elimino la procedure, serve solo per popolare
CALL popolamento_RegistroTemperatura('2021-10-01 00:00:00', '2021-10-31 00:00:00');
DROP PROCEDURE popolamento_RegistroTemperatura; 


-- RANDOMIZZAZIONE PRELIEVI -- 
UPDATE RegistroInterazioni
SET Preleva = ELT(0.5 + RAND() * 2, 'No','Si');
