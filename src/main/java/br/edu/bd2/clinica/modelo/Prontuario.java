package br.edu.bd2.clinica.modelo;

import java.time.LocalDate;

import javax.persistence.Entity;
import javax.persistence.Table;
import javax.persistence.Id;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Column;
import javax.persistence.OneToOne;
import javax.persistence.JoinColumn;
import javax.persistence.Enumerated;
import javax.persistence.EnumType;

@Entity
@Table(name = "prontuario")
public class Prontuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private LocalDate dataAbertura;

    @Enumerated(EnumType.STRING)
    private TipoSanguineo tipoSanguineo;

    @Column(length = 1000)
    private String alergias;

    @Column(length = 2000)
    private String observacoes;

    @OneToOne
    @JoinColumn(name = "paciente_id", unique = true, nullable = false)
    private Paciente paciente;

    public Prontuario() {
    }

    public Prontuario(LocalDate dataAbertura, TipoSanguineo tipoSanguineo,
                      String alergias, String observacoes, Paciente paciente) {
        this.dataAbertura = dataAbertura;
        this.tipoSanguineo = tipoSanguineo;
        this.alergias = alergias;
        this.observacoes = observacoes;
        this.paciente = paciente;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public LocalDate getDataAbertura() {
        return dataAbertura;
    }

    public void setDataAbertura(LocalDate dataAbertura) {
        this.dataAbertura = dataAbertura;
    }

    public TipoSanguineo getTipoSanguineo() {
        return tipoSanguineo;
    }

    public void setTipoSanguineo(TipoSanguineo tipoSanguineo) {
        this.tipoSanguineo = tipoSanguineo;
    }

    public String getAlergias() {
        return alergias;
    }

    public void setAlergias(String alergias) {
        this.alergias = alergias;
    }

    public String getObservacoes() {
        return observacoes;
    }

    public void setObservacoes(String observacoes) {
        this.observacoes = observacoes;
    }

    public Paciente getPaciente() {
        return paciente;
    }

    public void setPaciente(Paciente paciente) {
        this.paciente = paciente;
    }
}