CREATE TABLE jogadores (
    id SERIAL PRIMARY KEY,
    nickname VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    senha VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'Ativo'
        CHECK (status IN ('Ativo', 'Inativo', 'Banido'))
)

CREATE TABLE modalidades (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(50) UNIQUE NOT NULL
)

CREATE TABLE partidas (
	id serial PRIMARY KEY,
	jogador_id int REFERENCES jogadores(id) not null,
	modalidade_id int REFERENCES modalidades(id) not null,
	titulo VARCHAR(100) not null,
	data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	data_partida date not null,
	status varchar(50) DEFAULT 'Agendada' check (status in('Agendada', 'Em Andamento', 'Finalizada', 'Cancelada'))
)

CREATE TABLE historico_partidas (
    id SERIAL PRIMARY KEY,
    partida_id INT  REFERENCES partidas(id) NOT NULL,
    acao VARCHAR(100) not null,
    data_acao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)

------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_validar_partida()
RETURNS TRIGGER AS $$

DECLARE
    status_jogador VARCHAR(20);
BEGIN
    SELECT status
    INTO status_jogador
    FROM jogadores
    WHERE id = NEW.jogador_id;
	
IF NOT FOUND THEN
        RAISE EXCEPTION
        'Jogador nao encontrado';
		END IF;

IF status_jogador <> 'Ativo' THEN
        RAISE EXCEPTION
        'O jogador precisa estar ativo';
		END IF;
    	NEW.data_criacao := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_validar_partida
BEFORE INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION fn_validar_partida()

------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_registrar_historico()
RETURNS TRIGGER AS $$

BEGIN
    INSERT INTO historico_partidas
    (partida_id, acao)
    VALUES
    (NEW.id, 'Partida criada');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_registrar_historico
AFTER INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_historico()

------------------------------------------------------------------

INSERT INTO jogadores(nickname, email, senha, status) VALUES

('DuduPlayer', 'dudu@email.com', '123', 'Ativo'),
('ArthurGamer', 'arthur@email.com', '456', 'Ativo'),
('BrunoPro', 'bruno@email.com', '789', 'Banido')

INSERT INTO modalidades(nome) VALUES
('Valorant'),
('CS'),
('Fortnite')

INSERT INTO partidas
(jogador_id, modalidade_id, titulo, data_partida, status) VALUES

(1, 1, 'DuduPlayer x Time Alpha', '2026-12-01', 'Agendada'),
(2, 2, 'ArthurGamer x Time Beta', '2026-12-05', 'Agendada'),
(1, 3, 'DuduPlayer x Time Gamma', '2026-12-10', 'Agendada')


------------------------------------------------------------------


CREATE VIEW vw_painel_principal AS SELECT

    j.nickname,
    p.titulo AS partida,
    m.nome AS modalidade,
    p.data_partida,
    p.status
FROM partidas p
JOIN jogadores j
ON p.jogador_id = j.id
JOIN modalidades m
ON p.modalidade_id = m.id

------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_buscar_jogadores(termo TEXT)
RETURNS TABLE (nickname_jogador VARCHAR, email_jogador VARCHAR)
AS $$
BEGIN
RETURN QUERY

    SELECT
        jogadores.nickname,
        jogadores.email
    FROM jogadores
    WHERE jogadores.nickname
        ILIKE '%' || termo || '%'
    OR jogadores.email
        ILIKE '%' || termo || '%';
END;
$$ LANGUAGE plpgsql

------------------------------------------------------------------

CREATE VIEW vw_cronograma_partidas AS SELECT
    p.titulo AS partida,
    p.data_partida,
    p.status,
    p.data_partida - CURRENT_DATE AS dias_restantes,
    j.nickname AS jogador_responsavel
FROM partidas p
JOIN jogadores j
ON p.jogador_id = j.id
ORDER BY p.data_partida ASC