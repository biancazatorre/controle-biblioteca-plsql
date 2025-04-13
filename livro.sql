CREATE TABLE livro (
    id NUMBER PRIMARY KEY,
    titulo VARCHAR2(100),
    autor VARCHAR2(100),
    disponivel CHAR(1) DEFAULT 'S'
);

CREATE TABLE usuario(
    id NUMBER PRIMARY KEY,
    nome VARCHAR(100)
);

CREATE TABLE emprestimo (
    id number PRIMARY KEY,
    id_livro NUMBER,
    id_usuario NUMBER,
    data_emprestimo DATE,
    data_devolucao DATE,
    FOREIGN KEY (id_livro) REFERENCES livro(id),
    FOREIGN KEY (id_usuario) REFERENCES usuario(id)
);
CREATE TABLE log_emprestimo (
    id NUMBER PRIMARY KEY,
    id_livro NUMBER,
    data_evento DATE,
    evento VARCHAR(50)
);

CREATE OR REPLACE PROCEDURE emprestar_livro (
    p_id_livro IN NUMBER, 
    P_id_usuario IN NUMBER
) IS
    v_disp CHAR(1);
    v_id_emprestimo NUMBER;
BEGIN
    SELECT disponivel INTO v_disp FROM livro WHERE id = p_id_livro;
    
    IF v_disp = 'N' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Livro indisponível');
        END IF;

    SELECT NVL(MAX(id), 0) + 1 INTO v_id_emprestimo FROM emprestimo;

    INSERT INTO emprestimo (id, id_livro, id_usuario, data_emprestimo)
    VALUES (v_id_emprestimo, p_id_livro, p_id_usuario, SYSDATE);

    UPDATE livro SET disponivel = 'N' WHERE id = p_id_livro;

    DBMS_OUTPUT.PUT_LINE('Livro emprestado com sucesso');
END;

CREATE OR REPLACE PROCEDURE devolver_livro(
    p_id_livro IN NUMBER
) IS
BEGIN
    UPDATE emprestimo 
    SET data_devolucao = SYSDATE 
    WHERE id_livro = p_id_livro AND data_devolucao IS NULL;

    UPDATE livro SET disponivel = 'S' WHERE id = p_id_livro;

    INSERT INTO log_emprestimo (id, id_livro, data_evento, evento)
    VALUES (
        (SELECT NVL(MAX(id), 0) + 1 FROM log_emprestimo),
        p_id_livro,
        SYSDATE, 
        'DEVOLUÇÃO'
    );

    DBMS_OUTPUT.PUT_LINE('Livro devolvido com sucesso.');
END;

CREATE OR REPLACE FUNCTION verifica_disponibilidade (
    p_id_livro IN NUMBER
) RETURN VARCHAR2 IS
    v_disp CHAR(1);

BEGIN
    SELECT disponivel INTO v_disp FROM livro WHERE id = p_id_livro;

    IF v_disp = 'S' THEN
        RETURN 'Disponível';
    ElSE
        RETURN 'Indisponível';
    END IF;
END;

CREATE OR REPLACE PROCEDURE listar_livros_disponiveis IS

BEGIN 
    FOR r IN (
        SELECT id, titulo, autor
        FROM Livro
        WHERE disponivel = 'S'
    ) LOOP 
        DBMS_OUTPUT.PUT_LINE('['|| r.id ||']' || r.titulo || '-' || r.autor);
    END LOOP;
END;


-- TESTANDO
-- Livros
INSERT INTO livro VALUES (1, 'Dom Casmurro', 'Machado de Assis', 'S');
INSERT INTO livro VALUES (2, 'Capitães da Areia', 'Jorge Amado', 'S');

-- Usuários
INSERT INTO usuario VALUES (1, 'João');
INSERT INTO usuario VALUES (2, 'Maria');

COMMIT;

BEGIN
  listar_livros_disponiveis;
END;

BEGIN
  DBMS_OUTPUT.PUT_LINE(verifica_disponibilidade(1));
END;

BEGIN
  emprestar_livro(1, 1);
END;

BEGIN
  DBMS_OUTPUT.PUT_LINE(verifica_disponibilidade(1));
END;

BEGIN
  emprestar_livro(1, 2);
END;

BEGIN
  devolver_livro(1);
END;


BEGIN
  listar_livros_disponiveis;
END;