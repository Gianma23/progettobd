USE smart_home;
SET SESSION group_concat_max_len = 150000;
SET SESSION max_execution_time = 10000;
SET SQL_SAFE_UPDATES = 0;
-- ================================================ --
--                      Indice                      --
-- ================================================ --   

-- 1) Individuazione Items e Transazioni			
-- 2) Algoritmo Apriori								
-- 3) Tabella delle regole forti					
-- 4) Algoritmo Apriori: 							

-- Parametri per Apriori:
SET @Confidence = 0.8;
SET @Support = 0.01;

-- Parametri per definire le transazioni:
set @min_length = 2;
set @span = 20;

-- ================================================================================ --
--            1)        Individuazione di items e transazioni                       --
-- ================================================================================ --   

-- items: tabella Dispositivo

SELECT GROUP_CONCAT(
					CONCAT('`D', CodiceDispositivo, '`', ' INT DEFAULT 0') ORDER BY CodiceDispositivo
				   ) INTO @disp_list
FROM Dispositivo;

set @disp_list = concat('CREATE TABLE Transazione(',
						  ' ID INT AUTO_INCREMENT PRIMARY KEY, ', 
                            @disp_list, 
						  ' )engine = InnoDB default charset = latin1;');
                          
-- si crea la tabella Transazione, che ha come attributi ID, D1, D2....Dn                          
DROP TABLE IF EXISTS Transazione;
PREPARE create_table_Transazione FROM @disp_list;
EXECUTE create_table_Transazione;

-- -----------------------------------------
-- 1.1)	   Popolamento Transazione
-- -----------------------------------------
-- Una transazione è composta da un numero di dispositivi, usati da uno stesso account
-- nell'intervallo di tempo [RI.Inizio - @span, RI.Inizio + @span].
WITH transazioni AS (
    SELECT RI.Dispositivo, 
		   RI.Inizio, 
		   COUNT(DISTINCT RI2.Dispositivo) AS num_disp, 
		   GROUP_CONCAT(DISTINCT RI2.Dispositivo) AS lista -- lista dei dispositivi usati dallo stesso account nell'intervallo
	FROM RegistroInterazioni RI 
		 LEFT OUTER JOIN
         RegistroInterazioni RI2 ON (RI2.Inizio BETWEEN RI.Inizio - INTERVAL @span MINUTE
													   AND RI.Inizio + INTERVAL @span MINUTE
								     AND RI2.Account = RI.Account) -- stesso account
	GROUP BY RI.Dispositivo, RI.Inizio, RI.Account 
),
presenza_dispositivi as (
	SELECT Dispositivo, Inizio, CodiceDispositivo,
		   IF(FIND_IN_SET(CodiceDispositivo, lista) > 0, 1, 0) AS presente
	FROM transazioni 
		 CROSS JOIN
         Dispositivo
    WHERE num_disp >= @min_length
),
inserimento_transazione AS (
	SELECT Dispositivo, 
		   Inizio, 
		    GROUP_CONCAT(presente ORDER BY CodiceDispositivo) AS record
	FROM presenza_dispositivi 
    GROUP BY Inizio, Dispositivo
)

SELECT GROUP_CONCAT(CONCAT('(null,', record, ')') ) INTO @inserimento
FROM inserimento_transazione;

SET @inserimento = CONCAT('INSERT INTO Transazione VALUES ', @inserimento, ';');
 -- select LENGTH(@inserimento); --  per aggiustare group_concat_max_length
PREPARE insert_Transazione FROM @inserimento;
EXECUTE insert_Transazione;

-- si mostra la tabella popolata
TABLE Transazione;


-- ================================================================================ --
--            2)                  Algoritmo Apriori                                 --
-- ================================================================================ --   
-- -----------------------------------------------------
--  2.1)    FUNCTIONS E PROCEDURE DI UTILITA'
-- -----------------------------------------------------

-- --------------------------
-- Funzione per trovare Ck
-- --------------------------
DROP FUNCTION IF EXISTS GetC;
DELIMITER $$
CREATE FUNCTION GetC(k INT)
RETURNS TEXT DETERMINISTIC
BEGIN
	DECLARE i INT DEFAULT 1;
    DECLARE combination_select TEXT DEFAULT '';
	DECLARE vertical_without_repetition TEXT DEFAULT '';
    DECLARE horizontal_without_rep_select TEXT DEFAULT '';
	DECLARE count_support TEXT DEFAULT '';
    DECLARE count_support_where TEXT DEFAULT '';
    DECLARE result TEXT DEFAULT '';
    
	WHILE i < k DO
		-- si joina ogni elemento di combination con Dispositivo, poi su unisce, così
        -- da trovare la combinazione senza ripetizioni, in formato verticale
		SET vertical_without_repetition = CONCAT(vertical_without_repetition,
												 'SELECT ID1, ID2, CodiceDispositivo 
												  FROM combination 
												  INNER JOIN
												  Dispositivo D ON(D.CodiceDispositivo = Item', i,') 
                                                  UNION '
												 );
		
		-- prima parte del select di combination
        SET combination_select = CONCAT(combination_select, 'a.Item', i,', ');
		-- trasformo il formato delle combinazioni da verticale a orizzontale
        SET horizontal_without_rep_select = CONCAT(horizontal_without_rep_select, 'MAX(CASE WHEN rownum = ', i,' THEN CodiceDispositivo END) Item', i, ', ');
		-- where di support_transactions, l'item deve essere uguale a uno di quelli della combinazione in questione
        SET count_support_where = CONCAT(count_support_where, 'Item = Item', i, ' OR ');
        
        SET i = i + 1;
	END WHILE;

	-- ultimo elemento di horizontal_without_rep_select (i=k)
	SET horizontal_without_rep_select = CONCAT(horizontal_without_rep_select, 'MAX(CASE WHEN rownum = ', i,' THEN CodiceDispositivo END) Item', i);
    -- ultimo elemento di support_transactions_where (i=k)
	SET count_support_where = CONCAT(count_support_where, 'Item = Item', i);
     
    SET i = 1;
	WHILE i < k-1 DO
        -- si completa vertical_without_repetition joinando ogni elemento di b con Dispositivo
		SET vertical_without_repetition = CONCAT(vertical_without_repetition,
												 'SELECT ID1, ID2, CodiceDispositivo 
												  FROM combination 
												  INNER JOIN
												  Dispositivo D ON(D.CodiceDispositivo = Item',i,'Join)
                                                  UNION '
												 );
		-- seconda parte del select di combination, si rinomina ogni b.Itemi in ItemiJoin							
        SET combination_select = CONCAT(combination_select, 'b.Item', i,' AS Item', i,'Join, ');   
        
		SET i = i + 1;
	END WHILE;
    
	-- si completa combination_select
    SET combination_select = CONCAT(combination_select, 'b.Item', i,' AS Item', i,'Join, a.ID AS ID1, b.ID AS ID2');
    
    -- ultimo elemento di vertical_without_repetition (i=k-1)
	SET vertical_without_repetition = CONCAT(vertical_without_repetition,
											 'SELECT ID1, ID2, CodiceDispositivo 
											  FROM combination 
											  INNER JOIN
											  Dispositivo D ON(D.CodiceDispositivo = Item',i,'Join)'
											 );
	-- numero di transazioni che hanno tutti gli Item della combinazione										
	SET count_support = CONCAT('SELECT COUNT(*)
								FROM (
									  SELECT ID
									  FROM Items
									  WHERE ', count_support_where, '
									  GROUP BY ID
									  HAVING COUNT(*) = ', k,') AS Z'
							  );
	-- ----------------------
    --   RISULTATO FINALE
    -- ----------------------
	SET result = CONCAT(
						'WITH combination AS 
                        (
							SELECT ', combination_select,'
							FROM L',(k-1),' a 
								 INNER JOIN
								 L',(k-1),' b ON(a.ID < b.ID)  
						), 
                        vertical_without_rep AS
                        (', vertical_without_repetition,'), 
						horizontal_without_rep AS
                        (
							SELECT DISTINCT ', horizontal_without_rep_select, '
                            FROM (
								  SELECT *,
									@row:=if(@prev=CONCAT(ID1, ID2), @row,0) + 1 as rownum,
									@prev:= CONCAT(ID1, ID2)
								  FROM vertical_without_rep, (SELECT @row:=0, @prev:=null) AS R
								  ORDER BY ID1, ID2, CodiceDispositivo
								  ) AS S
						    GROUP BY ID1, ID2 
							HAVING MAX(rownum) = ', k,'
                        )
                        SELECT *, ('
							   , count_support, ') / (SELECT COUNT(*) FROM Items) AS Support
                        FROM horizontal_without_rep;'
					   );	-- fine concat
	RETURN result;
END $$
DELIMITER ;

-- --------------------------
-- Funzione per trovare Lk
-- --------------------------
DROP FUNCTION IF EXISTS GetL;
DELIMITER $$
CREATE FUNCTION GetL(k INT)
RETURNS TEXT DETERMINISTIC
BEGIN
	DECLARE item_list TEXT DEFAULT '';
	DECLARE i INT DEFAULT 1;
    WHILE i < k DO
		SET item_list = CONCAT(item_list, 'Item', i, ', ');
		SET i = i + 1;
    END WHILE;
    SET item_list = CONCAT(item_list, 'Item', i);	-- i=k
    
	RETURN CONCAT(
				   'SELECT ', item_list,', ROW_NUMBER() OVER (ORDER BY ', item_list,') AS ID ',
				   'FROM C', k,
				   ' WHERE Support > @Support');
END $$
DELIMITER ;
-- --------------------------------------
--  Funzione per trovare le REGOLE FORTI
-- --------------------------------------
DROP PROCEDURE IF EXISTS GetRules;
DELIMITER $$
CREATE PROCEDURE GetRules(IN k INT)
BEGIN
	DECLARE dim_X INT;
    DECLARE dim_Y INT;
    DECLARE X TEXT DEFAULT '';
    DECLARE Y TEXT DEFAULT '';
    DECLARE i INT DEFAULT 1;
    DECLARE j INT;
    DECLARE h INT;
    DECLARE X_list TEXT DEFAULT '';
    DECLARE Y_list TEXT DEFAULT '';
	DECLARE X_on TEXT DEFAULT '';
    DECLARE Y_on TEXT DEFAULT '';
    DECLARE X_supp DOUBLE;
    DECLARE Y_supp DOUBLE;
    DECLARE k_supp DOUBLE;
    DECLARE confidence DOUBLE;
    DECLARE k_supp_where TEXT DEFAULT '';
    DECLARE id INT;
    
	DECLARE finito INT DEFAULT 0;
    DECLARE cursor_Lk CURSOR FOR SELECT * FROM tmp_Lk;
    DECLARE CONTINUE HANDLER FOR NOT FOUND 
		SET finito = 1;
	-- Creazione della view dinamica per il cursore
	SET @v = CONCAT('CREATE OR REPLACE VIEW tmp_Lk AS
					 SELECT ID
                     FROM L', k, ';');
    PREPARE stm FROM @v;
    EXECUTE stm;

    
    OPEN cursor_Lk;
	loop_label: LOOP
     	FETCH cursor_Lk INTO id;
        IF finito = 1 THEN
			LEAVE loop_label;
		END IF;
        
		-- Prendo il supporto della riga joinando Lk con Ck
        
			SET @k = CONCAT('SELECT Support INTO @k_supp
							 FROM L', k,'
								  NATURAL JOIN
                                  C', k,'
							 WHERE ID =', id);
		PREPARE ksupp FROM @k;
		EXECUTE ksupp;
        -- ----------------------
        --  LOOP DI INSERIMENTI
        -- ----------------------
        SET dim_X = 1;
        WHILE dim_X <= k/2 DO 
			SET dim_Y = k - dim_X;
			SET i = 1;
            -- se k è pari e dim_X è uguale a k/2, i si ferma a k/2, altrimenti continua fino a k
			WHILE IF(k % 2 = 0 AND dim_X = k/2, i<=k/2, i<=k) DO
				SET j = (i + dim_X) % k;
                IF j = 0 THEN SET j = k; END IF;
				SET h = i;
				SET X_list = '', X_on = '';
				SET Y_list = '', Y_on = '';
				
				-- lista degli item di X
				WHILE h <> IF((dim_X+i-1)%k > 0, (dim_X+i-1)%k, k) DO
					SET X_list = CONCAT(X_list, 'Item', h, ', '' ,'' ,');
					SET h = h + 1;
					IF h > k THEN SET h = 1; END IF;
				END WHILE;
				SET X_list = CONCAT(X_list, 'Item', h);
				-- lista degli item di Y
				WHILE j <> IF(i-1 > 0, i - 1, k) DO 
					SET Y_list = CONCAT(Y_list, 'Item', j, ', '' ,'' ,');
					SET j = j + 1;
					IF j > k THEN SET j = 1; END IF;
				END WHILE;
				SET Y_list = CONCAT(Y_list, 'Item', j);
				-- ----------------------
				--    SET di X e Y
				-- ----------------------
				-- Si setta X
				SET @set_X = CONCAT('SELECT CONCAT(', X_list,') INTO @X
									 FROM L', k,' a
									 WHERE a.ID =', id);
                                     if k = 4 then select @set_X; end if;	-- debug
				PREPARE set_X FROM @set_X;
				EXECUTE set_X;
				-- Si setta Y
				SET @set_Y = CONCAT('SELECT CONCAT(', Y_list,') INTO @Y
									 FROM L', k,' a
									 WHERE a.ID =', id);
				PREPARE set_Y FROM @set_Y;
				EXECUTE set_Y;
				-- ------------------------
				--  Calcolo Supporti X e Y
				-- ------------------------
				-- ON clause per X
				SET h = i;
				SET j = 1;
                IF h + dim_X -1 > k THEN SET h = 1; END IF;
				WHILE j < dim_X DO
					SET X_on = CONCAT(X_on, 'L.Item', h, ' = C.Item', j, ' AND ');
					SET h = h + 1;
                    IF h = (i + dim_X) % k THEN 
						SET h = i;
					END IF;
					SET j = j + 1;
				END WHILE;
				SET X_on = CONCAT(X_on, 'L.Item', h, ' = C.Item', j);
				-- SUPPORTO DI X
				SET @Xsupp = CONCAT('SELECT Support INTO @X_supp
									 FROM L', k,' L
										  INNER JOIN
										  C', dim_X,' C ON ', X_on,' 
									 WHERE ID =', id);
				if @X = '5 ,6 ,9' then select @Xsupp; end if;	-- debug
				PREPARE Xsupp FROM @Xsupp;
				EXECUTE Xsupp;
				
				-- ON clause per Y
				SET h = (i + dim_X) % k;
                IF h = 0 THEN SET h = k; END IF;
				IF h + dim_Y -1 > k THEN SET h = 1; END IF;
				SET j = 1;
				WHILE j < dim_Y DO
					SET Y_on = CONCAT(Y_on, 'L.Item', h, ' = C.Item', j, ' AND ');
					SET h = h + 1;
                    IF h = i THEN 
						SET h = i + dim_X;
					END IF;
					SET j = j + 1;
				END WHILE;
				SET Y_on = CONCAT(Y_on, 'L.Item', h, ' = C.Item', j);

				-- SUPPORTO DI Y
				SET @Ysupp = CONCAT('SELECT Support INTO @Y_supp
									 FROM L', k,' L
										  INNER JOIN
										  C', dim_Y,' C ON ', Y_on,'
									 WHERE ID =', id);
				 if @Y = '17' then select @Ysupp; end if;	-- debug
				PREPARE Ysupp FROM @Ysupp;
				EXECUTE Ysupp;
				
				-- CALCOLO LA CONFIDENZA DI X-->Y
				SET confidence = @k_supp / @X_supp;
				INSERT IGNORE INTO Rules
				VALUES	(@X, @Y, confidence);
				-- CALCOLO LA CONFIDENZA DI X-->Y
				SET confidence = @k_supp / @Y_supp;
				INSERT IGNORE INTO Rules
				VALUES	(@Y, @X, confidence);
				
				SET i = i + 1;
			END WHILE;
            SET dim_X = dim_X + 1;
		END WHILE;
    END LOOP;
    CLOSE cursor_Lk;
END $$
DELIMITER ;


-- ================================================================================ --
--            3)                  Stored Procedure                                  --
-- ================================================================================ --  
DROP PROCEDURE IF EXISTS Apriori;
DELIMITER $$
CREATE PROCEDURE Apriori(IN max INT) -- max sono i passaggi massimi da fare
BEGIN
	DECLARE k INT DEFAULT 2;
    DECLARE i INT DEFAULT 2;
    
	-- tabella Item(ID, Item), serve per calcolare più velocemente il supporto
	SELECT GROUP_CONCAT( 
						CONCAT('SELECT ID, ', CodiceDispositivo,' as Item ' 
							   'FROM Transazione ',
							   'WHERE D', CodiceDispositivo, '<> 0') 
						SEPARATOR ' UNION ') INTO @transaction_items
	FROM Dispositivo;

	set @transaction_items = concat('create table Items as ',
										@transaction_items, ';');
                                        
	DROP TABLE IF EXISTS Items;
	PREPARE create_table_Items FROM @transaction_items;
	EXECUTE create_table_Items;
    
    -- CREO LA TABELLA C1(Item1, Support)
    DROP TABLE IF EXISTS C1;
    CREATE TABLE C1 AS
    SELECT Item AS Item1, COUNT(*) / (SELECT COUNT(*) FROM Transazione) AS Support
    FROM Items
    GROUP BY Item;
    
	-- CREO LA TABELLA L1(Item1, Support)
    DROP TABLE IF EXISTS L1;
    CREATE TABLE L1 AS
    SELECT *, ROW_NUMBER() OVER(ORDER BY Item1) AS ID
    FROM C1
    WHERE Support > @Support;
    
    -- LOOP da k = 2 fino a max, se Lk è vuoto si ferma
    loop_label: LOOP
		IF k > max THEN
			LEAVE loop_label;
		END IF;
        
		SET @dropCk = concat('DROP TABLE IF EXISTS C', k, ';');
		SET @getCk = concat('CREATE TABLE C',k,' AS ', GetC(k));
		SET @dropLk = concat('DROP TABLE IF EXISTS L', k, ';');
		SET @getLk = concat('CREATE TABLE L',k,' AS ', GetL(k));

        -- CREO LA TABELLA Ck
        PREPARE DropCk FROM @dropCk;
        EXECUTE DropCk;
        PREPARE GetCk FROM @getCk;
        EXECUTE GetCk;
        
        -- CREO LA TABELLA Lk
		PREPARE DropLk FROM @dropLk;
        EXECUTE DropLk;
        PREPARE GetLk FROM @getLk;
        EXECUTE GetLk;
        
        -- CONTROLLO che Lk non sia vuoto. Se sì, esco dal loop
        SET @Lk_empty = CONCAT('SELECT EXISTS (SELECT 1 FROM L', k,') INTO @empty;');
        PREPARE Lk_empty FROM @Lk_empty;
        EXECUTE Lk_empty;
        IF @empty = 0 THEN
			LEAVE loop_label;
		END IF;
        
		SET k = k + 1;
    END LOOP;
    
    -- Creo la tabella RULES
    DROP TABLE IF EXISTS Rules;
    CREATE TABLE Rules(
		X				VARCHAR(200) NOT NULL,
        Y				VARCHAR(200) NOT NULL,
        Confidence		DOUBLE NOT NULL,
        PRIMARY KEY(X, Y)
    )ENGINE = InnoDB DEFAULT CHARSET = latin1;
    
    SELECT k;
    WHILE i < k DO
		CALL GetRules(i);
        SET i = i + 1;
	END WHILE;
    TABLE Rules;
    
    DELETE FROM Rules
    WHERE Confidence < @Confidence;
    TABLE Rules;
END $$
DELIMITER ;

-- ================================ --
--   4) TEST STORED PROCEDURE       --
-- ================================ --
SELECT COUNT(*) INTO @num_disp
FROM Dispositivo;
CALL Apriori(@num_disp);


