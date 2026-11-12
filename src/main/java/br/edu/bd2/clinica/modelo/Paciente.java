package br.edu.bd2.clinica.modelo;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import javax.persistence.Entity;
import javax.persistence.Table;
import javax.persistence.Column;
import javax.persistence.OneToOne;
import javax.persistence.OneToMany;
import javax.persistence.JoinColumn;
import javax.persistence.FetchType;
import javax.persistence.CascadeType;
import javax.persistence.PrimaryKeyJoinColumn;
import javax.persistence.NamedQuery;

@Entity
@Table(name = "paciente")
@PrimaryKeyJoinColumn(name = "id")
@NamedQuery(
        name = "Paciente.buscarPorNome",
        query = "SELECT p FROM Paciente p WHERE LOWER(p.nome) LIKE LOWER(:nome)"
)
public class Paciente extends Pessoa {

    @Column(name = "data_cadastro")
    private LocalDate dataCadastro;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "convenio_id", unique = true)
    private Convenio convenio;

    @OneToOne(mappedBy = "paciente",
            cascade = CascadeType.ALL,
            orphanRemoval = true,
            fetch = FetchType.LAZY)
    private Prontuario prontuario;

    @OneToMany(mappedBy = "paciente",
            cascade = {CascadeType.PERSIST, CascadeType.MERGE},
            fetch = FetchType.LAZY)
    private List<Atendimento> atendimentos = new ArrayList<>();

    public Paciente() {
    }

    public Paciente(String nome, String email, String cpf,
                    String telefone, LocalDate dataNascimento,
                    Endereco endereco, LocalDate dataCadastro) {

        super(nome, email, cpf, telefone, dataNascimento, endereco);
        this.dataCadastro = dataCadastro;
    }

    public LocalDate getDataCadastro() {
        return dataCadastro;
    }

    public void setDataCadastro(LocalDate dataCadastro) {
        this.dataCadastro = dataCadastro;
    }

    public Convenio getConvenio() {
        return convenio;
    }

    public void setConvenio(Convenio convenio) {
        this.convenio = convenio;
    }

    public Prontuario getProntuario() {
        return prontuario;
    }

    public void setProntuario(Prontuario prontuario) {
        this.prontuario = prontuario;
    }

    public List<Atendimento> getAtendimentos() {
        return atendimentos;
    }

    public void setAtendimentos(List<Atendimento> atendimentos) {
        this.atendimentos = atendimentos;
    }
}