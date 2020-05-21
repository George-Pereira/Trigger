CREATE DATABASE aulatriggers01
go
USE aulatriggers01
/*evento de segunda ordem quando é usada uma query dml - quando um insert é feito, ela é executada
usada para garantir as regras de negócio
3 tipos de triggers After(for), BEFORE * - faz primeiro o que a trigger manda e depois , Instead of
Tabelas Deleted e Inserted - update cria as duas*/
CREATE TABLE servico(
id INT NOT NULL,
nome VARCHAR(100),
preco DECIMAL(7,2)
PRIMARY KEY(ID))
 
CREATE TABLE depto(
codigo INT not null,
nome VARCHAR(100),
total_salarios DECIMAL(7,2)
PRIMARY KEY(codigo))
 
CREATE TABLE funcionario(
id INT NOT NULL,
nome VARCHAR(100),
salario DECIMAL(7,2),
depto INT NOT NULL
PRIMARY KEY(id)
FOREIGN KEY (depto) REFERENCES depto(codigo))
 
INSERT INTO servico VALUES
(1, 'Orçamento', 20.00),
(2, 'Manutenção preventiva', 85.00)
 
INSERT INTO depto (codigo, nome) VALUES
(1,'RH'),
(2,'DTI')
 
DELETE funcionario WHERE id = 1
DELETE depto
DROP TRIGGER t_atualizasalarioTotal

INSERT INTO funcionario VALUES
(1, 'Fulano', 1537.89,2)
INSERT INTO funcionario VALUES
(2, 'Cicrano', 2894.44, 1)
INSERT INTO funcionario VALUES
(3, 'Beltrano', 984.69, 1)
INSERT INTO funcionario VALUES
(4, 'Tirano', 2487.18, 2)

SELECT * FROM depto
SELECT * FROM funcionario

CREATE TRIGGER t_viewdepto ON depto
FOR INSERT, UPDATE, DELETE
AS
BEGIN
	SELECT * FROM inserted
	SELECT * FROM deleted
END

INSERT INTO depto VALUES
(3, 'Almoxarifado', NULL)

CREATE DROP TRIGGER t_protegeservico ON servico
FOR DELETE
AS
BEGIN
	ROLLBACK TRANSACTION -- Desfaz a ultima transação
	RAISERROR('Não é permitido apagar dados de serviço, sujeito a pena de morte', 16, 1)
END

DELETE servico WHERE id=1


CREATE TRIGGER t_atualizasalarioTotal ON funcionario
FOR UPDATE, INSERT, DELETE
AS
	DECLARE		@cod_depto	INT,
				@nome	VARCHAR(100),
				@salario	DECIMAL(7,2),
				@conteudo	INT,
				@nulo		DECIMAL(7,2)
	BEGIN
		SELECT @cod_depto = depto, @nome = nome, @salario = salario FROM inserted
		SELECT @conteudo = (SELECT COUNT(id) FROM deleted)
		IF(@conteudo = 0)
		BEGIN
			SELECT @nulo = total_salarios FROM depto WHERE @cod_depto = codigo
			IF(@nulo IS NULL)
			BEGIN
				UPDATE depto SET total_salarios = @salario WHERE @cod_depto = codigo
			END
			ELSE
			BEGIN
				UPDATE depto SET total_salarios = (SELECT total_salarios FROM depto WHERE @cod_depto = codigo) + @salario WHERE @cod_depto = codigo
			END
		END
		ELSE
		BEGIN
			SET @conteudo = (SELECT COUNT(id) FROM inserted)
			IF(@conteudo <> 0)
			BEGIN
				UPDATE depto SET total_salarios = (SELECT total_salarios FROM depto WHERE @cod_depto = codigo) + @salario WHERE @cod_depto = codigo
			END
			ELSE
			BEGIN
				SELECT @cod_depto = depto, @nome = nome, @salario = salario FROM deleted
				UPDATE depto SET total_salarios = total_salarios - @salario WHERE @cod_depto = codigo
			END
	END
END