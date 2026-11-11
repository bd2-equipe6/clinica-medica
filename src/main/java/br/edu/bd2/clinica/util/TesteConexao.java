package br.edu.bd2.clinica.util;

import javax.persistence.EntityManager;

public class TesteConexao {

    public static void main(String[] args) {
        EntityManager em = JPAUtil.getEntityManager();
        try {
            Object versao = em.createNativeQuery("SELECT version()").getSingleResult();
            System.out.println("Conexão OK!");
            System.out.println(versao);
        } finally {
            em.close();
            JPAUtil.fechar();
        }
    }
}
