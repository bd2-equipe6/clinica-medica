package br.edu.bd2.clinica.ui;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.format.ResolverStyle;
import java.util.Scanner;

public class ConsoleUtil {
    private static final Scanner SC = new Scanner(System.in);
    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("dd/MM/uuuu")
            .withResolverStyle(ResolverStyle.STRICT);

    private static String proximaLinha() {
        if (!SC.hasNextLine()) {
            System.out.println("\nEntrada encerrada. Saindo...");
            System.exit(0);
        }
        return SC.nextLine();
    }

    public static String lerTexto(String rotulo) {
        while (true) {
            System.out.print(rotulo + ": ");
            String s = proximaLinha().trim();
            if (!s.isEmpty()) {
                return s;
            }
            System.out.println("  Campo obrigatório.");
        }
    }

    public static String lerTextoOpcional(String rotulo) {
        System.out.print(rotulo + " (Enter para pular): ");
        String s = proximaLinha().trim();
        return s.isEmpty() ? null : s;
    }

    public static String lerTextoOuManter(String rotulo, String atual) {
        System.out.print(rotulo + " [" + (atual == null ? "" : atual) + "]: ");
        String s = proximaLinha().trim();
        return s.isEmpty() ? atual : s;
    }

    public static String lerComando(String rotulo) {
        System.out.print(rotulo + ": ");
        return proximaLinha().trim().toLowerCase();
    }

    public static int lerInt(String rotulo) {
        while (true) {
            try {
                System.out.print(rotulo + ": ");
                return Integer.parseInt(proximaLinha().trim());
            } catch (NumberFormatException e) {
                System.out.println("  Digite um número inteiro válido.");
            }
        }
    }

    public static Long lerLong(String rotulo) {
        while (true) {
            try {
                System.out.print(rotulo + ": ");
                return Long.parseLong(proximaLinha().trim());
            } catch (NumberFormatException e) {
                System.out.println("  Digite um número válido.");
            }
        }
    }

    public static BigDecimal lerDecimal(String rotulo) {
        while (true) {
            System.out.print(rotulo + ": ");
            BigDecimal v = converterDecimal(proximaLinha());
            if (v != null) {
                return v;
            }
            System.out.println("  Valor inválido. Use um número maior que zero (ex.: 150.50).");
        }
    }

    public static BigDecimal lerDecimalOuManter(String rotulo, BigDecimal atual) {
        while (true) {
            System.out.print(rotulo + " [" + atual + "]: ");
            String s = proximaLinha().trim();
            if (s.isEmpty()) {
                return atual;
            }
            BigDecimal v = converterDecimal(s);
            if (v != null) {
                return v;
            }
            System.out.println("  Valor inválido. Use um número maior que zero (ex.: 150.50).");
        }
    }

    private static BigDecimal converterDecimal(String texto) {
        try {
            BigDecimal v = new BigDecimal(texto.trim().replace(",", "."));
            return v.signum() > 0 ? v : null;
        } catch (NumberFormatException e) {
            return null;
        }
    }

    public static LocalDate lerDataPassada(String rotulo) {
        while (true) {
            try {
                System.out.print(rotulo + " (dd/MM/aaaa): ");
                LocalDate d = LocalDate.parse(proximaLinha().trim(), FMT);
                if (d.isBefore(LocalDate.now())) {
                    return d;
                }
                System.out.println("  A data deve estar no passado.");
            } catch (DateTimeParseException e) {
                System.out.println("  Data inválida.");
            }
        }
    }

    public static String lerCpf(String rotulo) {
        while (true) {
            System.out.print(rotulo + ": ");
            String digitos = proximaLinha().replaceAll("\\D", "");
            if (digitos.length() == 11) {
                return digitos;
            }
            System.out.println("  O CPF deve ter 11 dígitos.");
        }
    }

    public static <E extends Enum<E>> E lerEnum(String rotulo, Class<E> tipo) {
        E[] valores = tipo.getEnumConstants();
        for (int i = 0; i < valores.length; i++) {
            System.out.println("  " + (i + 1) + " - " + valores[i]);
        }
        while (true) {
            int n = lerInt(rotulo);
            if (n >= 1 && n <= valores.length) {
                return valores[n - 1];
            }
            System.out.println("  Escolha um número da lista.");
        }
    }

    public static boolean confirmar(String pergunta) {
        System.out.print(pergunta + " (s/n): ");
        return proximaLinha().trim().equalsIgnoreCase("s");
    }

    public static String formatar(LocalDate d) {
        return d == null ? "-" : d.format(FMT);
    }

    public static String mensagemErro(Throwable e) {
        Throwable t = e;
        while (t.getCause() != null && t.getCause() != t) {
            t = t.getCause();
        }
        String msg = t.getMessage();
        if (msg == null) {
            return e.toString();
        }
        int quebra = msg.indexOf('\n');
        return quebra > 0 ? msg.substring(0, quebra) : msg;
    }

    public static boolean violouIntegridade(Throwable e) {
        return mensagemErro(e).toLowerCase().contains("violates");
    }
}
