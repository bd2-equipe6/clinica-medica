
package br.edu.bd2.clinica;

import br.edu.bd2.clinica.dao.GenericDAO;
import br.edu.bd2.clinica.modelo.CategoriaProcedimento;

public class TesteGenericDAO {

    public static void main(String[] args) {

        GenericDAO<CategoriaProcedimento, Long> dao =
                new GenericDAO<>(CategoriaProcedimento.class);

        CategoriaProcedimento categoria =
                new CategoriaProcedimento("Categoria Teste");

        dao.salvar(categoria);

        System.out.println("Categoria cadastrada!");
        System.out.println("ID: " + categoria.getId());

        CategoriaProcedimento encontrada =
                dao.buscarPorId(categoria.getId());

        System.out.println("Categoria encontrada: " + encontrada.getNome());

        System.out.println("\nCategorias cadastradas:");

        for (CategoriaProcedimento item : dao.listarTodos()) {
            System.out.println(item.getId() + " - " + item.getNome());
        }

        encontrada.setNome("Categoria Atualizada");
        dao.atualizar(encontrada);

        System.out.println("\nCategoria atualizada: "
                + dao.buscarPorId(categoria.getId()).getNome());

        boolean removida = dao.remover(categoria.getId());

        System.out.println("\nCategoria removida: " + removida);
    }
}
