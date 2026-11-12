package br.edu.bd2.clinica.modelo;

import java.util.ArrayList;
import java.util.List;

import javax.persistence.Entity;
import javax.persistence.Table;
import javax.persistence.Column;
import javax.persistence.ManyToMany;
import javax.persistence.JoinTable;
import javax.persistence.JoinColumn;
import javax.persistence.FetchType;
import javax.persistence.PrimaryKeyJoinColumn;

@Entity
@Table(name = "medico")
@PrimaryKeyJoinColumn(name = "id")
public class Medico extends Pessoa {

    @Column(unique = true, nullable = false)
    private String crm;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
            name = "medico_especialidade",
            joinColumns = @JoinColumn(name = "medico_id"),
            inverseJoinColumns = @JoinColumn(name = "especialidade_id")
    )
    private List<Especialidade> especialidades = new ArrayList<>();

    public Medico() {
    }

    public Medico(String nome, String email, String cpf,
                  String telefone, java.time.LocalDate dataNascimento,
                  Endereco endereco, String crm) {

        super(nome, email, cpf, telefone, dataNascimento, endereco);
        this.crm = crm;
    }

    public String getCrm() {
        return crm;
    }

    public void setCrm(String crm) {
        this.crm = crm;
    }

    public List<Especialidade> getEspecialidades() {
        return especialidades;
    }

    public void setEspecialidades(List<Especialidade> especialidades) {
        this.especialidades = especialidades;
    }
}