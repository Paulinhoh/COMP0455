/*
 * =================================================================================
 * BIBLIOTECAS NECESSÁRIAS (Pacote NuGet):
 * - Npgsql: É o provedor de dados .NET para o PostgreSQL. Permite a comunicação
 * direta com o banco de dados.
 *
 * COMANDO PARA ADICIONAR A BIBLIOTECA (via terminal na pasta do projeto):
 * dotnet add package Npgsql
 * =================================================================================
 */

// A biblioteca Npgsql é necessária para todas as operações com o PostgreSQL.
using Npgsql;

public class Program
{
    private const string ConnectionString = "Server=database-postgre-bd1-2025-1.cdwk8iisko7f.us-east-1.rds.amazonaws.com;Port=5432;User Id=professor;Password=professor;Database=postgres;SearchPath=\"Projeto Logico\";Include Error Detail=true;";

   public static void Main(string[] args)
{
    const string ConnectionString = "Server=database-postgre-bd1-2025-1.cdwk8iisko7f.us-east-1.rds.amazonaws.com;Port=5432;User Id=professor;Password=professor;Database=postgres;Include Error Detail=true;";

    // O bloco 'using' garante que a conexão será fechada mesmo que ocorram erros.
    using (var conn = new NpgsqlConnection(ConnectionString))
    {
        try
        {
            Console.WriteLine("Abrindo conexão com o banco de dados...");
            conn.Open();
            Console.WriteLine("Conexão aberta com sucesso!");

            using (var cmd = new NpgsqlCommand("SET search_path TO \"Projeto Logico\"", conn))
            {
                cmd.ExecuteNonQuery();
                Console.WriteLine("Schema 'Projeto Logico' definido com sucesso para a sessão atual.");
            }

            Console.WriteLine("--------------------------------------------");

            // --- ETAPA 1: Inserção com ROLLBACK ---
            TentaInserirAutorComRollback(conn);

            Console.WriteLine("\n--------------------------------------------");

            // --- ETAPA 2: Inserção com COMMIT ---
            InsereAutorComCommit(conn, 1, "Machado", "de Assis");
            InsereAutorComCommit(conn, 2, "Clarice", "Lispector");


            Console.WriteLine("\n--------------------------------------------");

            // --- ETAPA 3: Consulta dos Dados ---
            ConsultarAutores(conn);

        }
        catch (Exception ex)
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine($"Ocorreu um erro: {ex.Message}");
            if (ex.InnerException != null)
            {
                Console.WriteLine($"Detalhe: {ex.InnerException.Message}");
            }
            Console.ResetColor();
        }
        finally
        {
            // Garante que a conexão seja fechada ao final da execução.
            if (conn.State == System.Data.ConnectionState.Open)
            {
                conn.Close();
                Console.WriteLine("\n--------------------------------------------");
                Console.WriteLine("Conexão com o banco de dados fechada.");
            }
        }
    }
}
    /// <summary>
    /// Método que demonstra uma transação com ROLLBACK.
    /// Ele inicia uma transação, tenta inserir um dado e, em seguida,
    /// desfaz a operação com Rollback.
    /// </summary>
    public static void TentaInserirAutorComRollback(NpgsqlConnection conn)
    {
        Console.WriteLine("Iniciando transação para inserir 'Autor Fantasma' (será revertida)...");
        
        // 1. Inicia a transação
        using (var transaction = conn.BeginTransaction())
        {
            try
            {
                // Cria o comando SQL explícito para inserção
                var sql = "INSERT INTO Autor (id, primeiro_nome, sobrenome) VALUES (99, 'Autor', 'Fantasma')";

                // O comando é associado à conexão e à transação atual
                using (var cmd = new NpgsqlCommand(sql, conn, transaction))
                {
                    cmd.ExecuteNonQuery();
                    Console.WriteLine("Comando INSERT para 'Autor Fantasma' executado dentro da transação.");
                }

                // 2. Fluxo que executa o ROLLBACK
                // Aqui simulamos uma "falha" ou uma regra de negócio que força a reversão.
                Console.WriteLine("...Simulando uma falha ou condição que exige um rollback...");
                transaction.Rollback();
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.WriteLine("Transação revertida (ROLLBACK)! O 'Autor Fantasma' NÃO foi salvo no banco.");
                Console.ResetColor();
            }
            catch (Exception ex)
            {
                // Se um erro real ocorrer, também fazemos o rollback.
                transaction.Rollback();
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"Erro durante a transação, rollback executado: {ex.Message}");
                Console.ResetColor();
            }
        }
    }

    /// <summary>
    /// Método que demonstra uma transação com COMMIT.
    /// Insere um autor e, se tudo ocorrer bem, efetiva a transação.
    /// </summary>
    public static void InsereAutorComCommit(NpgsqlConnection conn, int id, string nome, string sobrenome)
    {
        Console.WriteLine($"Iniciando transação para inserir '{nome} {sobrenome}'...");
        
        // 1. Inicia a transação
        using (var transaction = conn.BeginTransaction())
        {
            try
            {
                var sql = "INSERT INTO Autor (id, primeiro_nome, sobrenome) VALUES (@id, @nome, @sobrenome)";
                
                using (var cmd = new NpgsqlCommand(sql, conn, transaction))
                {
                    cmd.Parameters.AddWithValue("id", id);
                    cmd.Parameters.AddWithValue("nome", nome);
                    cmd.Parameters.AddWithValue("sobrenome", sobrenome);
                    
                    cmd.ExecuteNonQuery();
                    Console.WriteLine($"Comando INSERT para '{nome} {sobrenome}' executado com sucesso.");
                }

                // 2. Fluxo final que executa o COMMIT
                // Se nenhuma exceção ocorreu, a transação é confirmada.
                transaction.Commit();
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine($"Transação confirmada (COMMIT)! O autor '{nome} {sobrenome}' foi salvo no banco.");
                Console.ResetColor();
            }
            catch (Exception ex)
            {
                transaction.Rollback();
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"Erro ao tentar inserir '{nome} {sobrenome}', rollback executado: {ex.Message}");
                Console.ResetColor();
            }
        }
    }

    /// <summary>
    /// Método para consultar e exibir todos os autores cadastrados na tabela 'Autor'.
    /// </summary>
    public static void ConsultarAutores(NpgsqlConnection conn)
    {
        Console.WriteLine("Consultando a tabela 'Autor' para verificar o resultado final...");

        var sql = "SELECT id, primeiro_nome, sobrenome FROM Autor ORDER BY id";
        
        using (var cmd = new NpgsqlCommand(sql, conn))
        {
            using (var reader = cmd.ExecuteReader())
            {
                Console.WriteLine("\n--- Lista de Autores no Banco ---");
                Console.WriteLine("ID\tNome Completo");
                Console.WriteLine("---------------------------------");

                if (!reader.HasRows)
                {
                    Console.WriteLine("Nenhum autor encontrado.");
                }

                while (reader.Read())
                {
                    Console.WriteLine($"{reader.GetInt32(0)}\t{reader.GetString(1)} {reader.GetString(2)}");
                }
                Console.WriteLine("---------------------------------");
            }
        }
    }
}