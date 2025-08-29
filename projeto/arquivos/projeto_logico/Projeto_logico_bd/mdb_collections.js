db.createCollection("usuarios", {
    validator: {
      $jsonSchema: {
        bsonType: "object",
        required: ["_id", "primeiro_nome", "sobrenome", "data_nascimento", "email", "celular", "endereco"],
        properties: {
          _id: { bsonType: "string" },
          primeiro_nome: { bsonType: "string" },
          sobrenome: { bsonType: "string" },
          data_nascimento: { bsonType: "string", pattern: "^\\d{4}-\\d{2}-\\d{2}$" },
          email: {
            bsonType: "array",
            items: { bsonType: "string", pattern: "^.+@.+\\..+$" }
          },
          celular: {
            bsonType: "array",
            items: { bsonType: "string", pattern: "^\\d{11}$" }
          },
          endereco: {
            bsonType: "object",
            required: ["pais", "estado", "cidade", "bairro", "rua", "cep"],
            properties: {
              pais: { bsonType: "string" },
              estado: { bsonType: "string" },
              cidade: { bsonType: "string" },
              bairro: { bsonType: "string" },
              rua: { bsonType: "string" },
              cep: { bsonType: "string", pattern: "^\\d{5}-\\d{3}$" }
            }
          }
        }
      }
    }
});
db.createCollection("funcionarios", {
    validator: {
      $jsonSchema: {
        bsonType: "object",
        required: ["matricula", "usuario_cpf"],
        properties: {
          matricula: { bsonType: "int" },
          usuario_cpf: { bsonType: "string" }
        }
      }
    }
});
db.createCollection("cliente", {
    validator: {
      $jsonSchema: {
        bsonType: "object",
        required: ["usuario_cpf", "livros_digitais_baixados"],
        properties: {
          usuario_cpf: { bsonType: "string" },
          livros_digitais_baixados: {
            bsonType: "array",
            items: {
              bsonType: "object",
              required: ["isbn", "titulo"],
              properties: {
                isbn: { bsonType: "string" },
                titulo: { bsonType: "string" }
              }
            }
          }
        }
      }
    }
});
db.createCollection("editoras", {
    validator: {
      $jsonSchema: {
        bsonType: "object",
        required: ["_id", "nome"],
        properties: {
          _id: { bsonType: "string" },
          nome: { bsonType: "string" }
        }
      }
    }
});
db.createCollection("autores", {
    validator: {
      $jsonSchema: {
        bsonType: "object",
        required: ["_id", "nome", "livros_escritos"],
        properties: {
          _id: { bsonType: "int" },
          nome: {
            bsonType: "object",
            required: ["primeiro_nome", "sobrenome"],
            properties: {
              primeiro_nome: { bsonType: "string" },
              sobrenome: { bsonType: "string" }
            }
          },
          livros_escritos: {
            bsonType: "array",
            items: {
              bsonType: "object",
              required: ["isbn", "titulo"],
              properties: {
                isbn: { bsonType: "string" },
                titulo: { bsonType: "string" }
              }
            }
          }
        }
      }
    }
});
db.createCollection("livros", {
    validator: {
      $jsonSchema: {
        bsonType: "object",
        required: [
          "_id", "titulo", "edicao", "num_paginas", "data_cadastro",
          "editora_cnpj", "funcionario_matricula", "data_publicacao",
          "autores", "categorias", "digital", "fisico"
        ],
        properties: {
          _id: { bsonType: "string" },
          titulo: { bsonType: "string" },
          edicao: { bsonType: "string" },
          num_paginas: { bsonType: "int" },
          data_cadastro: { bsonType: "date" },
          editora_cnpj: { bsonType: "string" },
          funcionario_matricula: { bsonType: "int" },
          data_publicacao: { bsonType: "string", pattern: "^\\d{4}-\\d{2}-\\d{2}$" },
          autores: {
            bsonType: "array",
            items: {
              bsonType: "object",
              required: ["autor_id", "nome"],
              properties: {
                autor_id: { bsonType: "int" },
                nome: { bsonType: "string" }
              }
            }
          },
          categorias: {
            bsonType: "array",
            items: { bsonType: "string" }
          },
          digital: {
            bsonType: "object",
            properties: {
              tamanho_mb: { bsonType: "double" }
            }
          },
          fisico: {
            bsonType: "object",
            required: ["secao_id", "exemplares"],
            properties: {
              secao_id: { bsonType: "int" },
              exemplares: {
                bsonType: "array",
                items: {
                  bsonType: "object",
                  required: ["numero", "status"],
                  properties: {
                    numero: { bsonType: "int" },
                    status: { bsonType: "string", enum: ["disponível", "emprestado"] }
                  }
                }
              }
            }
          }
        }
      }
    }
});
db.createCollection("reservas", {
    validator: {
      $jsonSchema: {
        bsonType: "object",
        required: ["_id", "status", "data_reserva", "cliente_usuario_cpf", "livros_fisicos"],
        properties: {
          _id: { bsonType: "int" },
          status: { bsonType: "string" },
          data_reserva: { bsonType: "string", pattern: "^\\d{4}-\\d{2}-\\d{2}$" },
          cliente_usuario_cpf: { bsonType: "string" },
          livros_fisicos: {
            bsonType: "array",
            items: {
              bsonType: "object",
              required: ["isbn"],
              properties: {
                isbn: { bsonType: "string" }
              }
            }
          }
        }
      }
    }
});
db.createCollection("secao", {
    validator: {
      $jsonSchema: {
        bsonType: "object",
        required: ["_id", "localizador"],
        properties: {
          _id: { bsonType: "int" },
          localizador: {
            bsonType: "object",
            required: ["estante", "coluna", "altura"],
            properties: {
              estante: { bsonType: "string" },
              coluna: { bsonType: "int" },
              altura: { bsonType: "int" }
            }
          }
        }
      }
    }
});
db.createCollection("emprestimos", {
    validator: {
      $jsonSchema: {
        bsonType: "object",
        required: ["_id", "cliente_usuario_cpf", "data_emprestimo", "status", "quant_livros", "itens"],
        properties: {
          _id: { bsonType: "int" },
          cliente_usuario_cpf: { bsonType: "string" },
          data_emprestimo: { bsonType: "date" },
          status: { bsonType: "string" },
          quant_livros: { bsonType: "int" },
          itens: {
            bsonType: "array",
            items: {
              bsonType: "object",
              required: ["_id", "livro_isbn", "exemplar_numero", "data_prevista"],
              properties: {
                _id: { bsonType: "int" },
                livro_isbn: { bsonType: "string" },
                exemplar_numero: { bsonType: "int" },
                data_prevista: { bsonType: "string", pattern: "^\\d{4}-\\d{2}-\\d{2}$" },
                data_entrega: {
                  bsonType: ["null", "string"],
                  pattern: "^\\d{4}-\\d{2}-\\d{2}$"
                }
              }
            }
          }
        }
      }
    }
});
db.createCollection("multas", {
    validator: {
      $jsonSchema: {
        bsonType: "object",
        required: ["_id", "descricao", "preco", "emprestimo_id", "item_emprestimo_id"],
        properties: {
          _id: { bsonType: "int" },
          descricao: { bsonType: "string" },
          preco: { bsonType: "double" },
          emprestimo_id: { bsonType: "int" },
          item_emprestimo_id: { bsonType: "int" }
        }
      }
    }
});
            