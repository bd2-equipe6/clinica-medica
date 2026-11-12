package br.edu.bd2.clinica.modelo;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

import javax.persistence.Entity;
import javax.persistence.Table;
import javax.persistence.Id;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Column;
import javax.persistence.ManyToOne;
import javax.persistence.OneToMany;
import javax.persistence.JoinColumn;
import javax.persistence.FetchType;

@Entity
@Table(name = "procedimento")
public class Procedimento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String codigo;

    @Column(nullable = false)
    private String nome;

    @Column(name = "valor_base", precision = 10, scale = 2)
    private BigDecimal valorBase;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "categoria_id", nullable = false)
    private CategoriaProcedimento categoria;

    @OneToMany(mappedBy = "procedimento", fetch = FetchType.LAZY)
    private List<ItemAtendimento> itensAtendimento = new ArrayList<>();

    public Procedimento() {
    }

    public Procedimento(String codigo, String nome,
                        BigDecimal valorBase,
                        CategoriaProcedimento categoria) {
        this.codigo = codigo;
        this.nome = nome;
        this.valorBase = valorBase;
        this.categoria = categoria;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getCodigo() {
        return codigo;
    }

    public void setCodigo(String codigo) {
        this.codigo = codigo;
    }

    public String getNome() {
        return nome;
    }

    public void setNome(String nome) {
        this.nome = nome;
    }

    public BigDecimal getValorBase() {
        return valorBase;
    }

    public void setValorBase(BigDecimal valorBase) {
        this.valorBase = valorBase;
    }

    public CategoriaProcedimento getCategoria() {
        return categoria;
    }

    public void setCategoria(CategoriaProcedimento categoria) {
        this.categoria = categoria;
    }

    public List<ItemAtendimento> getItensAtendimento() {
        return itensAtendimento;
    }

    public void setItensAtendimento(List<ItemAtendimento> itensAtendimento) {
        this.itensAtendimento = itensAtendimento;
    }
}