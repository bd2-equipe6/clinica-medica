package br.edu.bd2.clinica.ui;

import br.edu.bd2.clinica.util.JPAUtil;

public class Main {
    public static void main(String[] args) {
        MenuPaciente menuPaciente = new MenuPaciente();
        MenuProcedimento menuProcedimento = new MenuProcedimento();
        ValidadorDados validador = new ValidadorDados();

        try {
            int op;
            do {
                System.out.println("\n===== SISTEMA DA CLÍNICA MÉDICA =====");
                System.out.println("1 - Pacientes");
                System.out.println("2 - Procedimentos");
                System.out.println("3 - Validar dados gerados");
                System.out.println("0 - Sair");
                op = ConsoleUtil.lerInt("Opção");
                switch (op) {
                    case 1: menuPaciente.executar(); break;
                    case 2: menuProcedimento.executar(); break;
                    case 3: validador.executar(); break;
                    case 0: System.out.println("Encerrando..."); break;
                    default: System.out.println("Opção inválida.");
                }
            } while (op != 0);
        } finally {
            JPAUtil.fechar();
        }
    }
}
