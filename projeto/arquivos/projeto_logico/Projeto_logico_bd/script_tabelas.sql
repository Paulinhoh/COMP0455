-- Remove o schema se ele já existir, para uma execução limpa do script (opcional)
DROP SCHEMA IF EXISTS "Projeto Logico" CASCADE;

-- Cria o Schema para organizar os objetos do banco de dados
CREATE SCHEMA IF NOT EXISTS "Projeto Logico";

-- Define o schema padrão para a sessão atual
SET search_path TO "Projeto Logico";

-- -----------------------------------------------------
-- Definição de Domínios (DOMAIN)
-- -----------------------------------------------------

-- Domínio para CPF, garantindo que contenha exatamente 11 dígitos numéricos
CREATE DOMAIN DOM_CPF AS VARCHAR(11)
  CHECK (VALUE ~ '^[0-9]{11}$');

-- Domínio para CNPJ, garantindo que contenha exatamente 14 dígitos numéricos
CREATE DOMAIN DOM_CNPJ AS VARCHAR(14)
  CHECK (VALUE ~ '^[0-9]{14}$');

-- Domínio para CEP, garantindo que contenha exatamente 8 dígitos numéricos
CREATE DOMAIN DOM_CEP AS VARCHAR(8)
  CHECK (VALUE ~ '^[0-9]{8}$');

-- Domínio para status de empréstimo
CREATE DOMAIN DOM_STATUS AS CHAR(1)
  CHECK (VALUE IN ('A', 'D', 'C')); -- A: Ativo, D: Devolvido, C: Cancelado

-- -----------------------------------------------------
-- Tabela Usuario
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Usuario (
  cpf DOM_CPF NOT NULL,
  data_nascimento DATE NOT NULL,
  sobrenome VARCHAR(45) NOT NULL,
  primeiro_nome VARCHAR(45) NOT NULL,
  email VARCHAR(45)[] NULL,
  celular VARCHAR(15)[] NULL,
  PRIMARY KEY (cpf)
);

-- -----------------------------------------------------
-- Tabela Autor
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Autor (
  id INT NOT NULL,
  primeiro_nome VARCHAR(45) NOT NULL,
  sobrenome VARCHAR(45) NOT NULL,
  PRIMARY KEY (id)
);

-- -----------------------------------------------------
-- Tabela Editora
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Editora (
  cnpj DOM_CNPJ NOT NULL,
  nome VARCHAR(45) NOT NULL UNIQUE,
  PRIMARY KEY (cnpj)
);

-- -----------------------------------------------------
-- Tabela "Seção" (nome com caractere especial precisa de aspas)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS "Seção" (
  id INT NOT NULL,
  estante VARCHAR(45) NOT NULL,
  altura VARCHAR(45) NOT NULL,
  coluna VARCHAR(45) NOT NULL,
  PRIMARY KEY (id)
);

-- -----------------------------------------------------
-- Tabela Funcionario
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Funcionario (
  matricula INT NOT NULL,
  usuario_cpf DOM_CPF NOT NULL,
  PRIMARY KEY (matricula),
  CONSTRAINT fk_Funcionario_Usuario1
    FOREIGN KEY (usuario_cpf)
    REFERENCES Usuario (cpf)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

-- -----------------------------------------------------
-- Tabela Livro
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Livro (
  isbn VARCHAR(13) NOT NULL, -- ISBN é mais apropriado como VARCHAR
  titulo VARCHAR(100) NOT NULL,
  edicao VARCHAR(45) NOT NULL,
  num_paginas INT NOT NULL CHECK (num_paginas > 0),
  editora_cnpj DOM_CNPJ NOT NULL,
  data_cadastro TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  funcionario_matricula INT NOT NULL,
  PRIMARY KEY (isbn),
  CONSTRAINT fk_Livro_Editora1
    FOREIGN KEY (editora_cnpj)
    REFERENCES Editora (cnpj)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_Livro_Funcionario1
    FOREIGN KEY (funcionario_matricula)
    REFERENCES Funcionario (matricula)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

-- -----------------------------------------------------
-- Tabela Digital (Herança de Livro)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Digital (
  tamanho_mb REAL NOT NULL CHECK (tamanho_mb > 0),
  livro_isbn VARCHAR(13) NOT NULL,
  PRIMARY KEY (livro_isbn),
  CONSTRAINT fk_Digital_Livro1
    FOREIGN KEY (livro_isbn)
    REFERENCES Livro (isbn)
    ON DELETE CASCADE -- Se o livro for deletado, a versão digital também será
    ON UPDATE CASCADE
);

-- -----------------------------------------------------
-- Tabela Categoria
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Categoria (
  id INT NOT NULL,
  nome VARCHAR(45) NOT NULL UNIQUE,
  PRIMARY KEY (id)
);

-- -----------------------------------------------------
-- Tabela "Endereço"
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS "Endereço" (
  id SERIAL, -- Usando SERIAL para autoincremento, mais comum em Postgres
  cep DOM_CEP NOT NULL,
  rua VARCHAR(45) NOT NULL,
  bairro VARCHAR(45) NOT NULL,
  pais VARCHAR(45) NOT NULL DEFAULT 'Brasil',
  estado VARCHAR(45) NOT NULL,
  cidade VARCHAR(45) NOT NULL,
  PRIMARY KEY (id)
);

-- -----------------------------------------------------
-- Tabela Reserva
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Reserva (
  id SERIAL,
  status DOM_STATUS NOT NULL DEFAULT 'A', -- A: Ativa, C: Cancelada
  data_reserva DATE NOT NULL DEFAULT CURRENT_DATE,
  PRIMARY KEY (id)
);

-- -----------------------------------------------------
-- Tabela Fisico (Herança de Livro)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Fisico (
  livro_isbn VARCHAR(13) NOT NULL,
  secao_id INT NOT NULL,
  PRIMARY KEY (livro_isbn),
  CONSTRAINT fk_Fisico_Livro1
    FOREIGN KEY (livro_isbn)
    REFERENCES Livro (isbn)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_Fisico_Seção1
    FOREIGN KEY (secao_id)
    REFERENCES "Seção" (id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

-- -----------------------------------------------------
-- Tabela Exemplar
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Exemplar (
  numero INT NOT NULL,
  fisico_livro_isbn VARCHAR(13) NOT NULL,
  PRIMARY KEY (numero, fisico_livro_isbn),
  CONSTRAINT fk_Exemplar_Fisico1
    FOREIGN KEY (fisico_livro_isbn)
    REFERENCES Fisico (livro_isbn)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- -----------------------------------------------------
-- Tabela Cliente
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Cliente (
  usuario_cpf DOM_CPF NOT NULL,
  PRIMARY KEY (usuario_cpf),
  CONSTRAINT fk_Cliente_Usuario1
    FOREIGN KEY (usuario_cpf)
    REFERENCES Usuario (cpf)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- -----------------------------------------------------
-- Tabela Emprestimo
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Emprestimo (
  id SERIAL,
  data_emprestimo TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status DOM_STATUS NOT NULL DEFAULT 'A', -- A: Ativo, D: Devolvido
  quant_livros INT NOT NULL CHECK (quant_livros > 0),
  cliente_usuario_cpf DOM_CPF NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_Emprestimo_Cliente1
    FOREIGN KEY (cliente_usuario_cpf)
    REFERENCES Cliente (usuario_cpf)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

-- -----------------------------------------------------
-- Tabela de Relacionamento: Escreve (Autor-Livro)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Escreve (
  livro_isbn VARCHAR(13) NOT NULL,
  autor_id INT NOT NULL,
  PRIMARY KEY (livro_isbn, autor_id),
  CONSTRAINT fk_Livro_has_Autor_Livro
    FOREIGN KEY (livro_isbn)
    REFERENCES Livro (isbn)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_Livro_has_Autor_Autor1
    FOREIGN KEY (autor_id)
    REFERENCES Autor (id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

-- -----------------------------------------------------
-- Tabela de Relacionamento: Pertence (Livro-Categoria)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Pertence (
  livro_isbn VARCHAR(13) NOT NULL,
  categoria_id INT NOT NULL,
  PRIMARY KEY (livro_isbn, categoria_id),
  CONSTRAINT fk_Livro_has_Categoria_Livro1
    FOREIGN KEY (livro_isbn)
    REFERENCES Livro (isbn)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_Livro_has_Categoria_Categoria1
    FOREIGN KEY (categoria_id)
    REFERENCES Categoria (id)
    ON DELETE RESTRICT -- Impede apagar categoria se houver livros nela
    ON UPDATE CASCADE
);

-- -----------------------------------------------------
-- Tabela de Relacionamento: Possui (Fisico-Reserva)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Possui (
  fisico_livro_isbn VARCHAR(13) NOT NULL,
  reserva_id INT NOT NULL,
  PRIMARY KEY (fisico_livro_isbn, reserva_id),
  CONSTRAINT fk_Fisico_has_Reserva_Fisico1
    FOREIGN KEY (fisico_livro_isbn)
    REFERENCES Fisico (livro_isbn)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_Fisico_has_Reserva_Reserva1
    FOREIGN KEY (reserva_id)
    REFERENCES Reserva (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- -----------------------------------------------------
-- Tabela de Relacionamento: Endereco_Usuario
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Endereco_Usuario (
  endereco_id INT NOT NULL,
  usuario_cpf DOM_CPF NOT NULL,
  PRIMARY KEY (endereco_id, usuario_cpf),
  CONSTRAINT fk_Endereco_has_Usuario_Endereco1
    FOREIGN KEY (endereco_id)
    REFERENCES "Endereço" (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_Endereco_has_Usuario_Usuario1
    FOREIGN KEY (usuario_cpf)
    REFERENCES Usuario (cpf)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- -----------------------------------------------------
-- Tabela de Relacionamento: Realiza (Cliente-Reserva)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Realiza (
  cliente_usuario_cpf DOM_CPF NOT NULL,
  reserva_id INT NOT NULL,
  PRIMARY KEY (cliente_usuario_cpf, reserva_id),
  CONSTRAINT fk_Cliente_has_Reserva_Cliente1
    FOREIGN KEY (cliente_usuario_cpf)
    REFERENCES Cliente (usuario_cpf)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_Cliente_has_Reserva_Reserva1
    FOREIGN KEY (reserva_id)
    REFERENCES Reserva (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- -----------------------------------------------------
-- Tabela Exemplar_emprestado
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Exemplar_emprestado (
  id SERIAL,
  exemplar_numero INT NOT NULL,
  exemplar_fisico_livro_isbn VARCHAR(13) NOT NULL,
  emprestimo_id INT NOT NULL,
  status DOM_STATUS NOT NULL,
  data_prevista DATE NOT NULL,
  data_entrega DATE NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_Exemplar_has_Emprestimo_Exemplar1
    FOREIGN KEY (exemplar_numero , exemplar_fisico_livro_isbn)
    REFERENCES Exemplar (numero , fisico_livro_isbn)
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
  CONSTRAINT fk_Exemplar_has_Emprestimo_Emprestimo1
    FOREIGN KEY (emprestimo_id)
    REFERENCES Emprestimo (id)
    ON DELETE NO ACTION
    ON UPDATE CASCADE
);

-- -----------------------------------------------------
-- Tabela Multa
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Multa (
  id SERIAL,
  descricao VARCHAR(255) NULL,
  preco NUMERIC(10, 2) NOT NULL CHECK (preco >= 0),
  exemplar_emprestado_id INT NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_Multa_Exemplar_emprestado1
    FOREIGN KEY (exemplar_emprestado_id)
    REFERENCES Exemplar_emprestado (id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
);

-- -----------------------------------------------------
-- Tabela de Relacionamento: Baixa (Digital-Cliente)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS Baixa (
  digital_livro_isbn VARCHAR(13) NOT NULL,
  cliente_usuario_cpf DOM_CPF NOT NULL,
  data_download TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (digital_livro_isbn, cliente_usuario_cpf),
  CONSTRAINT fk_Digital_has_Cliente_Digital1
    FOREIGN KEY (digital_livro_isbn)
    REFERENCES Digital (livro_isbn)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_Digital_has_Cliente_Cliente1
    FOREIGN KEY (cliente_usuario_cpf)
    REFERENCES Cliente (usuario_cpf)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);