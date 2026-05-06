-- 1.1 Adicione uma tabela de log ao sistema do restaurante. Ajuste cada procedimento para que ele registre 
-- a data em que a operação aconteceu 
-- o nome do procedimento executado 
CREATE TABLE tb_log (
    id_log SERIAL PRIMARY KEY,
    data_execucao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    procedimento VARCHAR(200)
);

CREATE OR REPLACE PROCEDURE sp_ola_usuario (nome VARCHAR(200)) 
LANGUAGE plpgsql 
AS $$
BEGIN 
    RAISE NOTICE 'Olá, %', nome;
    RAISE NOTICE 'Olá, %', $1;

    INSERT INTO tb_log (procedimento) VALUES ('sp_ola_usuario');
END; 
$$;

CREATE OR REPLACE PROCEDURE sp_acha_maior (INOUT valor1 INT, IN valor2 INT) 
LANGUAGE plpgsql 
AS $$
BEGIN 
    IF valor2 > valor1 THEN 
        valor1 := valor2; 
    END IF;

    INSERT INTO tb_log (procedimento) VALUES ('sp_acha_maior');
END; 
$$;

CREATE OR REPLACE PROCEDURE sp_calcula_media (VARIADIC valores INT[]) 
LANGUAGE plpgsql 
AS $$
DECLARE 
    media NUMERIC(10, 2) := 0; 
    valor INT; 
BEGIN 
    FOREACH valor IN ARRAY valores LOOP 
        media := media + valor; 
    END LOOP;

    RAISE NOTICE 'A média é %', media / array_length(valores, 1);

    INSERT INTO tb_log (procedimento) VALUES ('sp_calcula_media');
END; 
$$;

CREATE OR REPLACE PROCEDURE sp_cadastrar_cliente (
    IN nome VARCHAR(200), 
    IN codigo INT DEFAULT NULL
) 
LANGUAGE plpgsql 
AS $$
BEGIN 
    IF codigo IS NULL THEN 
        INSERT INTO tb_cliente (nome) VALUES (nome); 
    ELSE 
        INSERT INTO tb_cliente (codigo, nome) VALUES (codigo, nome); 
    END IF;

    INSERT INTO tb_log (procedimento) VALUES ('sp_cadastrar_cliente');
END; 
$$;

CREATE OR REPLACE PROCEDURE sp_criar_pedido (
    OUT cod_pedido INT,
    cod_cliente INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO tb_pedido (cod_cliente)
    VALUES (cod_cliente);

    SELECT LASTVAL() INTO cod_pedido;

    INSERT INTO tb_log (procedimento) VALUES ('sp_criar_pedido');
END;
$$;

CREATE OR REPLACE PROCEDURE sp_adicionar_item_a_pedido (
    IN cod_item INT,
    IN cod_pedido INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO tb_item_pedido (cod_item, cod_pedido) VALUES ($1, $2);

    UPDATE tb_pedido tb
    SET data_modificacao = CURRENT_TIMESTAMP 
    WHERE tb.cod_pedido = $2;

    INSERT INTO tb_log (procedimento) VALUES ('sp_adicionar_item_a_pedido');
END;
$$;

CREATE OR REPLACE PROCEDURE sp_calcular_valor_de_um_pedido (
    IN p_cod_pedido INT,
    OUT valor_total INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT SUM(i.valor)
    INTO valor_total
    FROM tb_pedido p
    INNER JOIN tb_item_pedido ip ON p.cod_pedido = ip.cod_pedido
    INNER JOIN tb_item i ON i.cod_item = ip.cod_item
    WHERE p.cod_pedido = p_cod_pedido;

    INSERT INTO tb_log (procedimento) VALUES ('sp_calcular_valor_de_um_pedido');
END;
$$;

CREATE OR REPLACE PROCEDURE sp_fechar_pedido (
    IN valor_a_pagar INT,
    IN p_cod_pedido INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    valor_total INT;
BEGIN
    CALL sp_calcular_valor_de_um_pedido(p_cod_pedido, valor_total);

    IF valor_a_pagar < valor_total THEN
        RAISE 'R$% insuficiente para pagar a conta de R$%', valor_a_pagar, valor_total;
    ELSE
        UPDATE tb_pedido tb
        SET data_modificacao = CURRENT_TIMESTAMP, status = 'fechado'
        WHERE tb.cod_pedido = p_cod_pedido;
    END IF;

    INSERT INTO tb_log (procedimento) VALUES ('sp_fechar_pedido');
END;
$$;

CREATE OR REPLACE PROCEDURE sp_calcular_troco (
    OUT troco INT,
    IN valor_a_pagar INT,
    IN valor_total INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    troco := valor_a_pagar - valor_total;

    INSERT INTO tb_log (procedimento) VALUES ('sp_calcular_troco');
END;
$$;

CREATE OR REPLACE PROCEDURE sp_obter_notas_para_compor_o_troco (
    OUT resultado VARCHAR(500),
    IN troco INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    notas200 INT := 0;
    notas100 INT := 0;
    notas50 INT := 0;
    notas20 INT := 0;
    notas10 INT := 0;
    notas5 INT := 0;
    notas2 INT := 0;
    moedas1 INT := 0;
BEGIN
    notas200 := troco / 200;
    notas100 := (troco % 200) / 100;
    notas50 := (troco % 200 % 100) / 50;
    notas20 := (troco % 200 % 100 % 50) / 20;
    notas10 := (troco % 200 % 100 % 50 % 20) / 10;
    notas5 := (troco % 200 % 100 % 50 % 20 % 10) / 5;
    notas2 := (troco % 200 % 100 % 50 % 20 % 10 % 5) / 2;
    moedas1 := (troco % 200 % 100 % 50 % 20 % 10 % 5 % 2);

    resultado := CONCAT(
        'Notas de 200: ', notas200, E'\n',
        'Notas de 100: ', notas100, E'\n',
        'Notas de 50: ', notas50, E'\n',
        'Notas de 20: ', notas20, E'\n',
        'Notas de 10: ', notas10, E'\n',
        'Notas de 5: ', notas5, E'\n',
        'Notas de 2: ', notas2, E'\n',
        'Moedas de 1: ', moedas1, E'\n'
    );

    INSERT INTO tb_log (procedimento) VALUES ('sp_obter_notas_para_compor_o_troco');
END;
$$;