package br.edu.bd2.clinica.util;

import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;
import javax.persistence.Persistence;

public class JPAUtil {

    private static final EntityManagerFactory EMF =
            Persistence.createEntityManagerFactory("clinicaPU");

    public static EntityManager getEntityManager() {
        return EMF.createEntityManager();
    }

    public static void fechar() {
        if (EMF.isOpen()) {
            EMF.close();
        }
    }
}
