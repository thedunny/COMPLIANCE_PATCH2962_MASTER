create or replace package csf_own.pk_int_view_cad is

-------------------------------------------------------------------------------------------------------
--| Especifica��o do pacote de procedimentos de integra��o e valida��o de Cadastros
--
-- Em 04/02/2021   - Wendel Albino - patch 2.9.5.5 / 2.9.6-2 e release 297
-- Redmine #75771  - Verificar agendamento de integra��o SPANI 
-- Rotina Alterada - pkb_integr_cad_geral / pkb_integr_empresa_geral ->inclusao nos sleects de multorg com rownum (nro_linhas) 
--                 -  para nao executar mais de uma vez as procedures por multiorg.
--
-- Em 10/07/2020 - Wendel Albino
-- Redmine #68319/68800 - Erros de agendamento de Integra��o 
-- Rotina Alterada - pkb_integracao_normal/ pkb_integracao, inclusao de parametro de entrada com nro_linhas (en_nro_linhas) para nao executar mais de uma vez procedures por multiorg.
--
-- Em 11/02/2020 - Eduardo Linden
-- Redmine #64760 - Verificar reposit�rio - Atividade #52790
-- Corre��o na type tab_csf_aglut_contabil. O campo ar_cod_agl passou de varchar2(2) para varchar2(30).
-- Rotina afetada: pkb_aglut_contabil
--
-- Em 22/01/2020   - Allan Magrini
-- Redmine #48957 - Inclus�o do campo de Valor do Diferencial de Al�quota em Informa��es dos Itens dos Documentos Fiscais do Bem.
-- Adicionada ev_valor in out na fase 61 valida��o atributo VL_DIF_ALIQ -- fase 3.3 adicionando na pk_csf_api_cad.pkb_integr_itnf_bem_ativo_imob o campo ev_valor
-- Rotina Alterada -  pkb_itnf_bem_ativo_imob_ff, pkb_itnf_bem_ativo_imob
--
-- Em 09/10/2019        - Karina de Paula
-- Redmine #52654/59814 - Alterar todas as buscar na tabela PESSOA para retornar o MAX ID
-- Rotinas Alteradas    - Trocada a fun��o pk_csf.fkg_cnpj_empresa_id pela pk_csf.fkg_empresa_id_cpf_cnpj
-- N�O ALTERE A REGRA DESSAS ROTINAS SEM CONVERSAR COM EQUIPE
--
-- ===== ABAIXO EST� EM ORDEM ANTIGA CRESCENTE ========================================================================== --
--
-- Em 03/05/2011 - Angela In�s.
-- Inclu�do processo de item de marca comercial.
--
-- Em 23/04/2012 - Angela In�s.
-- Alterar a coluna inscr_prod para tamanho de 15.
--
-- Em 29/11/2012 - Angela In�s.
-- Ficha HD 64680 - Eliminar caracteres especiais para integra��o dos campos: cnpj, cpf e ie.
-- Rotinas: pkb_pessoa.
--
-- Em 11/01/2013 - Vanessa N F Ribeiro.
-- Ficha HD 65502 - Integra��o de novos campos de complemnto do item .
--
-- Em 20/03/2013 - Angela In�s.
-- Ficha HD 66478 - Integra��o individual n�o recupera os dados da empresa referente a banco de dados (dblink, etc.).
-- Rotinas: pkb_hist_padrao, pkb_centro_custo, pkb_plano_conta, pkb_bem_ativo_imob e pkb_item.
--
-- Em 23/05/2013 - Angela In�s.
-- Incluir ordena��o por cpf_cnpj, cod_cta e dt_inc_alt, para recupera��o dos dados de planos de contas.
-- Rotina: pkb_plano_conta.
--
-- Em 12/07/2013 - Angela In�s.
-- Incluir os par�metros de data inicial e final para a execu��o da integra��o dos cadastros gerais.
-- Rotina: pkb_integracao.
-- Incluir a rotina para gera��o de dados dos bens imobilizados.
-- Rotina: pkb_softfacil.
--
-- Em 18/07/2013 - Angela In�s.
-- Corre��o na integra��o de cadastro de BENS, ordenando por DM_IDENT_MERC, para que recuperem primeiro os c�digos que s�o BENS e depois os COMPONENTES.
-- Rotina: pkb_bem_ativo_imob.
--
-- Em 22/07/2013 - Rog�rio Silva.
-- RedMine #399
-- Rotinas: pkb_bem_ativo_imob e cria��o da pkb_bem_ativo_imob_compl
--
-- Em 24/07/2013 - Rog�rio Silva.
-- RedMine #398
-- Cria��o dos procedimentos: pkb_grupo_pat, pkb_subgrupo_pat e pkb_rec_imp_subgrupo_pat
--
-- Em 25/07/2013 - Rog�rio Silva.
-- RedMine #401
-- Cria��o dos procedimentos: pkb_itnf_bem_ativo_imob e pkb_itnf_bem_ativo_imob.
--
-- Em 26/07/2013 - Rog�rio Silva.
-- RedMine #400
-- Cria��o do procedimento: pkb_rec_imp_bem_ativo_imob.
--
-- Em 30/07/2013 - Rog�rio Silva.
-- RedMine #490
-- * Altera��o do procedimento: pkb_bem_ativo_imob, foi incluido a chamada da rotina que verifica se integrou a informa��o da utiliza��o do bem.
-- * Adicionado o campo COD_CCUS no procedimento pkb_subgrupo_pat.
--
-- Em 31/07/2013 - Rog�rio Silva.
-- RedMine #490
-- * Altera��o do procedimento: pkb_bem_ativo_imob, foi incluido a chamada da rotina que verifica se integrou os impostos do bem.
--
-- Em 09/08/2013 - Angela In�s.
-- Corre��o na mensagem do processo de gera��o de dados do SGI para integra��o dos bens do ativo imobilizado.
--
-- Em 03/03/2014 - Angela In�s.
-- Redmine #2043 - Alterar a API de integra��o de cadastros incluindo o cadastro de Item componente/insumo.
--
-- Em 17/03/2014 - Angela In�s.
-- Alterar a API de integra��o de cadastros incluindo o cadastro de Item componente/insumo em todos os processos de integra��o.
--
-- Em 07/08/2014 - Angela In�s.
-- Redmine #3712 - Corre��o nos processos - Eliminar o comando dbms_output.put_line.
--
-- Em 26/09/2014 - Rog�rio Silva
-- Redmine #4067 - Processo de contagem de registros integrados do ERP (Agendamento de integra��o)
-- Rotinas: pkb_pessoa, pkb_unidade, pkb_item, pkb_integracao, pkb_integracao_normal, pkb_integr_cad_geral e pkb_integr_empresa_geral.
--
-- Em 16/10/2014 - Rog�rio Silva
-- Redmine #4067 - Processo de contagem de registros integrados do ERP (Agendamento de integra��o)
--
-- Em 21/10/2014 - Rog�rio Silva
-- Redmine #4864 - Alterar tamanho m�ximo da coluna "NRO" do vetor referente a "PESSOA" na integra��o de cadastros
--
-- Em 21/10/2014 - Rog�rio Silva
-- Redmine #4067 - Processo de contagem de registros integrados do ERP (Agendamento de integra��o)
--
-- Em 05/11/2014 - Rog�rio Silva
-- Redmine #5020 - Processo de contagem de registros integrados do ERP (Agendamento de integra��o)
--
-- Em 24/11/2014 - Leandro Savenhago
-- Redmine #5298 - Adequa��o da PK_INT_VIEW_CAD para Mult-Organiza��o
-- Altera��es:
--
-- Em 28/11/2014 - Rog�rio Silva
-- Redmine #5367 - Adequa��o da PK_INT_VIEW_CAD para Mult-Organiza��o
-- Altera��es referente a grupos de patrim�nio
--
-- Em 01/11/2014 - Rog�rio Silva
-- Redmine #5367 - Adequa��o da PK_INT_VIEW_CAD para Mult-Organiza��o
-- Altera��es referente a Bens do ativo imobilizado
--
-- Em 02/11/2014 - Rog�rio Silva
-- Redmine #5367 - Adequa��o da PK_INT_VIEW_CAD para Mult-Organiza��o
-- Adapta��o dos processos de Natureza da Opera��o, Informa��es complementares do documento fiscal,
-- e Observa��o do lan�amento fiscal para o multorg e web-service
--
-- Em 05/11/2014 - Rog�rio Silva
-- Redmine #5367 - Adequa��o da PK_INT_VIEW_CAD para Mult-Organiza��o
-- Troca de chamada de procedures de ecd para cad: pkb_integr_Plano_Conta, pkb_integr_pc_referen, pkb_integr_Centro_Custo
--
-- Em 26/12/2014 - Angela In�s.
-- Atualiza��o das vers�es das vari�veis de contadores com processo Mult-Organiza��o.
--
-- Em 06/01/2015 - Angela In�s.
-- Redmine #5616 - Adequa��o dos objetos que utilizam dos novos conceitos de Mult-Org.
--
-- Em 25/02/2015 - Angela In�s.
-- Redmine #6577 - Erro Suframa.
-- Corrigir a integra��o de PESSOA: utilizar a fkg_converte, replace(',','.','-','/') por nulo, e recuperar 9 caracteres.
-- Rotina: pkb_pessoa.
--
-- Em 25/02/2015 - Rog�rio Silva.
-- Redmine #6314 - Analisar os processos na qual a tabela UNIDADE � utilizada.
--
-- Em 19/03/2015 - Rog�rio Silva.
-- Redmine #6315 - Analisar os processos na qual a tabela EMPRESA � utilizada.
-- Adicionado o multorg_id na recupera��o de dados da empresa conforme cnpj/cpf
-- Rotina: pkb_dados_bco_empr.
--
-- Em 23/04/2015 - Angela In�s.
-- Redmine #7784 - Erro Integra��o Cadastro (COOPERB).
-- Problema: Na view de integra��o o c�digo do Item est� vindo com caractere especial ficando: 'DEMONSTRAC?O'.
-- No Compliance esse item j� est� cadastrado como: 'DEMONSTRA\00C7\00C3O'.
-- Na leitura para identificar se o c�digo j� existe no Compliance os caracteres n�o s�o eliminados, e ao gravar sim, por isso o erro de UK.
-- 1) Passamos a informar o c�digo do item a ser integrado na rotina pk_int_view_cad.pkb_item, quando houver erro no processo.
--
-- Em 03/12/2015 - Rog�rio Silva.
-- Redmine #13378 - Corrigir procedimento de integra��o de cadastros
--
-- Em 15/12/2015 - Leandro Savenhago.
-- Redmine #11501 - Agendamento de integra��o do tipo "Empresa logada" apenas funciona para empresas de mult org padr�o (cd = 1)
-- Rotina: pkb_integracao.
-- Alterado para passar como par�metro o ID da empresa em vez do CNPJ
--
-- Em 15/12/2015 - Leandro Savenhago.
-- Redmine #13481 - [CADASTRO] DM_TIPO_PESSOA = 2 'EXTERIOR'
-- Rotina: pkb_pessoa.
-- Realizado o teste para verificar se os dados do CPF_CNPJ s�o numericos
--
-- Em 06/04/2016 - F�bio Tavares
-- Redmine #17036 - Foi feita a Integra��o de Subcontas Correlatas.
--
-- Em 24/06/2016 - Angela In�s.
-- Redmine #20644 - Integra��o de Cadastros Gerais - Bem do Ativo Imobilizado.
-- Alterar os processos de integra��o dos campos FlexField/S�rie que comparam se o campo est� Nulo.
-- Rotina: pkb_itnf_bem_ativo_imob_ff e pkb_nf_bem_ativo_imob_ff.
--
-- Em 09/08/2016 - Angela In�s.
-- Redmine #22231 - Corre��o na integra��o do ITEM - Campos Mult-Org - Flex-Field.
-- N�o considerar os campos de mult-org, COD_MULT_ORG e HASH_MULT_ORG, para integra��o do ITEM.
-- Rotina: pkb_ler_item_ff.
--
-- Em 28/12/2016 - F�bio Tavares.
-- Redmine #26707 - Ajuste na Integra��o de ITEM de Insumo, que passou a ser filho do ITEM.
-- Rotina: pkb_ler_item, pkb_ler_item_insumo.
--
-- Em 06/01/2017 - Angela In�s.
-- Redmine #27030 - Na integra��o do item insumo est� exigindo o NCM.
-- Alterar no processo de integra��o de Item Insumo o objeto de refer�ncia para os logs de inconsist�ncia. Utilizar "ITEM_INSUMO'.
-- Rotina: pkb_item_insumo.
--
-- Em 19/01/2017 - Angela In�s.
-- Redmine #27547 - Corre��o na integra��o de Item - Campos FlexField.
-- Identificar se a view de integra��o est� ativa para integra��o dos dados (checagem na tabela obj_util_integr.dm_ativo).
-- Rotina: pkb_ler_item_ff.
--
-- Em 15/02/2017
-- Redmine #27870 - Implementar a integra��o Table/View de Cadastros, package PK_INT_VIEW_CAD,
-- os procedimentos de leiaute e chamada da integra��o para os tipos VW_CSF_PARAM_ITEM_ENTR e VW_CSF_PARAM_OPER_FISCAL_ENTR.
-- Rotina : pkb_ler_item_fornc_eu
--
-- Em 21/02/2017 - F�bio Tavares.
-- Redmine #28581 - Unidade a ser convertida (**) esta invalida. (Sal Cisne)
-- Rotina: pkb_conv_unid
--
-- Em 01/03/2017 - Leandro Savenhago
-- Redmine 28832- Implementar o "Par�metro de Formato de Data Global para o Sistema".
-- Implementar o "Par�metro de Formato de Data Global para o Sistema".
--
-- Em 15/03/2017 - Angela In�s.
-- Redmine #29359 - Corre��o na Integra��o de Cadastros - Fun��o de convers�o de caracteres.
-- Alterar em todos os processos de integra��o de cadastro, eliminando a fun��o de convers�o de caracteres (pk_csf.fkg_converte), nas condi��es (where).
-- Rotinas: todas.
--
-- Em 16/03/2017 - F�bio Tavares.
-- Redmine #29332 - Integra��o de Centro de Custo( Foi retirado a fun��o do fkg_converte dos processos de integra��o da flex-field )
--
-- Em 06/04/2017 - F�bio Tavares
-- Redmine #27483 - Melhorias referentes ao plano de contas referencial
-- Relacionado ao Periodo de Referencia de um plano de conta e centro de custo da empresa para o plano de conta do ECD.
--
--  Em 13/04/2017 - Melina carniel
-- Redmine #30177 - Altera��o do campo DESCRI��O do ITEM/Produto
-- Alterar o tamanho do campo DESCR_ITEM na view de integra��o VW_CSF_ITEM: de Varchar2 (60), para Varchar2 (120).
--
-- Em 26/05/2017 - F�bio Tavares
-- Redmine #31472 - INTEGRA��O AGLUTINA��O CONT�BIL
--
-- Em 23/06/2017 - Marcos Garcia
-- Redmine #32113 - Alterar o processo de integra��o de cadastro: PK_INT_VIEW_CAD.
-- Por conta da altera��o na felx-field VW_CSF_PC_REFEREN_FF, o processo de integra��o, agora, ir�
-- contar com o campo cod_ccus para a recupera��o dos dados.
--
--  Em 30/06/2017 - Leandro Savenhago
-- Redmine #31839 - CRIA��O DOS OBJETOS DE INTEGRA��O - STAFE
-- Cria��o do Procedimento PKB_STAFE
--
-- Em 22/08/2017 - F�bio Tavares
-- Redmine #33792 - Integra��o de Cadastros para o Sped Reinf - Integra��o INT_VIEW 
--
-- Em 26/09/2017 - Marcos Garcia
-- Redmine 34961 - Altera��o de campo das views
-- Alterado todos os campos cod_ind_bem para 60 caracteres.
--
-- Em 10/10/2017 - Marcelo Ono
-- Redmine #34945 - Corre��o na integra��o de Plano de Contas
-- Inclu�do a ordena��o por n�vel de plano de conta crescente, garantindo que os planos de contas superiores sejam cadastrados antes dos planos contas filhos. 
-- Rotina: pkb_plano_conta
--
-- Em 02/02/2018 - Angela In�s.
-- Redmine #39021 - Processo de Agendamento de Integra��o - altera��o nos processos do tipo Todas as Empresas.
-- Na tela/portal do agendamento, quando selecionamos o campo "Tipo" como sendo "Todas as empresas" (agend_integr.dm_tipo=3), o processo de agendamento
-- (pk_agend_integr.pkb_inicia_agend_integr), executa a rotina pk_agend_integr.pkb_inicia_agend_integr/pkb_agend_integr_csf.
-- Utilizando esse processo, incluir nas rotinas relacionadas a cada objeto de integra��o, o processo criado para o cliente Usina Santa F�, rotina com o nome
-- padr�o "PKB_STAFE". Essa rotina est� sendo utilizada nas integra��es, por�m quando o agendamento � feito por empresa (agend_integr.dm_tipo=1).
-- Com essa mudan�a a integra��o passar� a ser feita tamb�m para a op��o de "Todas as empresas".
-- Rotina: pkb_integr_cad_geral.
--
-- Em 07/02/2018 - Marcelo Ono
-- Redmine 38773 - Corre��es e implementa��es nos processos do REINF.
-- 1- Corrigido as mensagens de logs nas rotinas de integra��o do processo administrativo/judici�rio do EFD Reinf;
-- Rotina: pkb_ler_proc_adm_efd_reinf, pkb_ler_proc_adm_efd_reinf_ff, pkb_ler_procadmefdreinfinftrib.
--
-- Em 12/02/2018 - Marcelo Ono
-- Redmine #39282 - Implementado a Integra��o de Informa��es de pagamentos de impostos retidos/SPED REINF.
-- Rotina: pkb_pessoa, pkb_pessoa_info_pir.
--
-- Em 19/03/2018 - Angela In�s.
-- Redmine #40695 - Corre��o na integra��o de Bens do Ativo Imobilizado - Cadastros Gerais.
-- Considerar as informa��es de C�digo do Bem eliminando os caracteres especiais da mesma forma que � utilizado no Integra��o de CIAP.
-- Rotinas: pkb_bem_ativo_imob, pkb_bem_ativo_imob_ff, pkb_infor_util_bem, pkb_infor_util_bem_ff, pkb_bem_ativo_imob_compl e pkb_bem_ativo_imob_compl_ff.
-- Rotinas: pkb_nf_bem_ativo_imob, pkb_nf_bem_ativo_imob_ff, pkb_itnf_bem_ativo_imob, pkb_itnf_bem_ativo_imob_ff e pkb_rec_imp_bem_ativo_imob.
-- Rotina: pkb_rec_imp_bem_ativo_imob_ff.
--
-- Em 21/03/2018 - Angela In�s.
-- Redmine #40795 - Corre��o na Integra��o de Cadastro do BEM/Gerais e Integra��o do CIAP.
-- Deixar a Integra��o do Cadastro do BEM n�o considerando a fun��o FKG_CONVERTE na coluna COD_IND_BEM, em todas as views de integra��o.
-- Rotinas: pkb_bem_ativo_imob, pkb_bem_ativo_imob_ff, pkb_infor_util_bem, pkb_infor_util_bem_ff, pkb_bem_ativo_imob_compl e pkb_bem_ativo_imob_compl_ff.
-- Rotinas: pkb_nf_bem_ativo_imob, pkb_nf_bem_ativo_imob_ff, pkb_itnf_bem_ativo_imob, pkb_itnf_bem_ativo_imob_ff e pkb_rec_imp_bem_ativo_imob.
-- Rotina: pkb_rec_imp_bem_ativo_imob_ff.
--
-- Em 18/05/2018 - Angela In�s.
-- Redmine #42611 - Processo de Integra��o de Cadastro - Monitoramento.
-- Executar o processo do Cliente Usina Santa F� apenas uma vez no processo de Integra��o para todas as empresas.
-- Rotina: pkb_integr_cad_geral.
--
-- Em 28/06/2018 - Angela In�s.
-- Redmine #44509 - Incluir a coluna de percentual de rateio de item nos par�metros da DIPAM-GIA.
-- 1) Incluir no documento de leiaute de Integra��o de Cadastro a coluna de percentual de rateio de item, PERC_RATEIO_ITEM, nos par�metros da DIPAM-GIA.
-- 2) Alterar o processo de Integra��o e Valida��o dos Cadastros Gerais, incluindo a coluna de percentual de rateio de item, PERC_RATEIO_ITEM, nos par�metros da DIPAM-GIA.
-- Rotina: pkb_ler_param_dipamgia.
--
-- Em 19/09/2018 - Marcos Ferreira
-- Redmine #46825 - Altera��o tamanho campo tabela "PROC_ADM_EFD_REINF"
-- Solicita��o: Adequa��o de novo layout expedido pelo Governo - Adequa��o de tamanho de campos
-- Altera��es: Aumento do tamanho do campo cod_ident_vara de varchar2(2) para varchar2(4)
-- Procedures Alteradas: type tab_proc_adm_efd_reinf
--
-- Em 18/10/2018 - Karina de Paula
-- Redmine #39990 - Adpatar o processo de gera��o da DIRF para gerar os registros referente a pagamento de rendimentos a participantes localizados no exterior
-- Rotina Alterada: pk_int_view_cad.pkb_pessoa    => Alterada a chamada da pkb_pessoa_ff com a inclus�o do COD_NIF e carrega a pk_csf_api_cad.gt_row_pessoa.cod_nif;
-- Rotina Alterada: pk_int_view_cad.pkb_pessoa_ff => Inclu�do o COD_NIF nos par�metros de entrada da pb, inclu�do COD_NIF nos campos da view VW_CSF_PESSOA_FF
--                                                   e inclu�da a chamada da NOVA pk_csf_api_cad.pkb_val_atrib_nif;
--                                                   e inclu�da a chamada da NOVA pk_csf_api_cad.pkb_val_atrib_nif;
--
-- Em 18/02/2019 - Angela In�s.
-- Redmine #51632 - Falha na integra��o de cadastros gerais - ORA-06502 PL/SQL numeric or value error (ALTA GENETICS).
-- Conforme solicita��o, foi necess�rio incluir o comando FKG_CONVERTE na coluna de Centro de Custo devido a ferramenta utilizada pelo cliente. A defini��o dos 
-- campos da tabela faz com que o tamanho fique maior na leitura do processo da Compliance, causando inconsit�ncia de dados.
-- Esse comando foi aplicado em v�rios processos de Integra��o devido a necessidade desse cliente.
-- Rotina: pkb_pc_referen.
--
-- Em 12/09/2019 - Luis Marques
-- Redmine #58615 - Erros no SPED DF
-- Rotina Alterada: pkb_pessoa_ff - Incluido novo campo flex-field para inclus�o da Natureza/Setor da pessoa
--                  (0 - Pessoa Setor Privado / 1 - Pessoa Setor Publico)
--
--
-------------------------------------------------------------------------------------------------------

-- Especifica��o de array

--| Informa��es de Pessoa
   type tab_csf_pessoa is record ( cod_part           varchar2(60)
                                 , dm_tipo_pessoa     number(1)
                                 , nome               varchar2(60)
                                 , fantasia           varchar2(60)
                                 , lograd             varchar2(60)
                                 , nro                varchar2(60)
                                 , cx_postal          varchar2(10)
                                 , compl              varchar2(60)
                                 , bairro             varchar2(60)
                                 , cidade_ibge        varchar2(7)
                                 , cep                number(8)
                                 , fone               varchar2(14)
                                 , fax                varchar2(14)
                                 , email              varchar2(60)
                                 , cod_siscomex_pais  number(4)
                                 , cpf_cnpj           varchar2(14)
                                 , rg_ie              varchar2(14)
                                 , iest               varchar2(14)
                                 , im                 varchar2(15)
                                 , suframa            varchar2(14)
                                 , inscr_prod         varchar2(15)
                                 );
--
   type t_tab_csf_pessoa is table of tab_csf_pessoa index by binary_integer;
   vt_tab_csf_pessoa t_tab_csf_pessoa;
--
--| Informa��es Flex-Field de Pessoa
   type tab_csf_pessoa_ff is record ( cod_part           varchar2(60)
                                    , atributo           varchar2(30)
                                    , valor              varchar2(255)
                                    );
--
   type t_tab_csf_pessoa_ff is table of tab_csf_pessoa_ff index by binary_integer;
   vt_tab_csf_pessoa_ff t_tab_csf_pessoa_ff;
--
--| Informa��es de Par�metros de Pessoa
   type tab_csf_pessoa_tipo_param is record ( cod_part           varchar2(60)
                                            , cd_tipo_param      varchar2(10)
                                            , valor_tipo_param   varchar2(10)
                                            );
--
   type t_tab_csf_pessoa_tipo_param is table of tab_csf_pessoa_tipo_param index by binary_integer;
   vt_tab_csf_pessoa_tipo_param t_tab_csf_pessoa_tipo_param;
--
--| Informa��es de pagamentos de impostos retidos/SPED REINF
   type tab_csf_pessoa_info_pir is record ( cod_part              varchar2(60)
                                          , dm_ind_nif            number(1)
                                          , nif_benef             varchar2(20)   
                                          , cd_fonte_pagad_reinf  varchar2(3)    
                                          , dt_laudo_molestia     date
                                          );

   type t_tab_csf_pessoa_info_pir is table of tab_csf_pessoa_info_pir index by binary_integer;
   vt_tab_csf_pessoa_info_pir t_tab_csf_pessoa_info_pir;
--
--| Informa��es Flex-Field de Unidades de Medida
   type tab_csf_unidade_ff is record ( sigla_unid         varchar2(6)
                                     , atributo           varchar2(30)
                                     , valor              varchar2(255)
                                     );
--
   type t_tab_csf_unidade_ff is table of tab_csf_unidade_ff index by binary_integer;
   vt_tab_csf_unidade_ff t_tab_csf_unidade_ff;
--
--| Informa��es de Unidades de Medida
   type tab_csf_unidade is record ( sigla_unid        varchar2(6)
                                  , descr             varchar2(20) );
--
   type t_tab_csf_unidade is table of tab_csf_unidade index by binary_integer;
   vt_tab_csf_unidade t_tab_csf_unidade;
--
--| Informa��es de produtos e/ou servi�os Flex Field
   type tab_csf_item_ff is record ( cpf_cnpj      varchar2(14)
                                  , cod_item      varchar2(60)
                                  , atributo      varchar2(30)
                                  , valor         varchar2(255)
                                  );
--
   type t_tab_csf_item_ff is table of tab_csf_item_ff index by binary_integer;
   vt_tab_csf_item_ff t_tab_csf_item_ff;
--
--| Informa��es de produtos e/ou servi�os
   type tab_csf_item is record ( cpf_cnpj      varchar2(14)
                               , cod_item      varchar2(60)
                               , descr_item    varchar2(120)
                               , sigla_unid    varchar2(6)
                               , dm_orig_merc  number(1)
                               , tipo_item     varchar2(2)
                               , cod_ncm       varchar2(8)
                               , ex_tipi       varchar2(2)
                               , cod_barra     varchar2(255)
                               , cod_ant_item  varchar2(60)
                               , tipo_servico  varchar2(6)
                               , aliq_icms     number(5,2)
                               , cod_prod_anp  number(9) );
--
   type t_tab_csf_item is table of tab_csf_item index by binary_integer;
   vt_tab_csf_item t_tab_csf_item;
--
--| Informa��es de C�digos de Grupos por Marca Comercial/Refrigerante
   type tab_csf_item_marca_comerc is record ( cpf_cnpj    varchar2(14)
                                            , cod_item    varchar2(60)
                                            , dm_cod_tab  varchar2(2)
                                            , cod_gru     varchar2(2)
                                            , marca_com   varchar2(60) );
--
   type t_tab_csf_item_marca_comerc is table of tab_csf_item_marca_comerc index by binary_integer;
   vt_tab_csf_item_marca_comerc t_tab_csf_item_marca_comerc;
--
--| Informa��es de convers�o de unidade do item
   type tab_csf_conv_unid is record ( cpf_cnpj    varchar2(14)
                                    , cod_item    varchar2(60)
                                    , sigla_unid  varchar2(60)
                                    , fat_conv    number(13,6) );
--
   type t_tab_csf_conv_unid is table of tab_csf_conv_unid index by binary_integer;
   vt_tab_csf_conv_unid t_tab_csf_conv_unid;
--
--| Informa��es de convers�o de unidade do item
   type tab_csf_conv_unid_ff is record ( cpf_cnpj    varchar2(14)
                                       , cod_item    varchar2(60)
                                       , sigla_unid  varchar2(60)
                                       , atributo    varchar2(30)
                                       , valor       varchar2(255) );
--
   type t_tab_csf_conv_unid_ff is table of tab_csf_conv_unid_ff index by binary_integer;
   vt_tab_csf_conv_unid_ff t_tab_csf_conv_unid_ff;
--
--| Informa��es Flex Field dos grupos do patrimonio
   type tab_csf_grupo_pat_ff is record ( cd            varchar2(10)
                                       , atributo      varchar2(30)
                                       , valor         varchar2(255)
                                       );
--
   type t_tab_csf_grupo_pat_ff is table of tab_csf_grupo_pat_ff index by binary_integer;
   vt_tab_csf_grupo_pat_ff t_tab_csf_grupo_pat_ff;
--
--| Informa��es dos grupos do patrimonio
   type tab_csf_grupo_pat is record ( cd       varchar2(10)
                                    , descr    varchar2(50) );
--
   type t_tab_csf_grupo_pat is table of tab_csf_grupo_pat index by binary_integer;
   vt_tab_csf_grupo_pat t_tab_csf_grupo_pat;
--
--| Informa��es dos subgrupos do patrimonio
   type tab_csf_subgrupo_pat is record ( cd_grupopat          varchar2(10)
                                       , cd_subgrupopat       varchar2(10)
                                       , descr                varchar2(50)
                                       , vida_util_fiscal     number(3)   
                                       , vida_util_real       number(3)   
                                       , dm_formacao          number(1)   
                                       , dm_deprecia          number(1)   
                                       , dm_tipo_rec_pis      number(1)   
                                       , dm_tipo_rec_cofins   number(1) 
                                       , cod_ccus             varchar2(60) );
--
   type t_tab_csf_subgrupo_pat is table of tab_csf_subgrupo_pat index by binary_integer;
   vt_tab_csf_subgrupo_pat t_tab_csf_subgrupo_pat;
--
--| Informa��es Flex Field dos subgrupos do patrimonio
   type tab_csf_subgrupo_pat_ff is record ( cd_grupopat          varchar2(10)
                                          , cd_subgrupopat       varchar2(10)
                                          , atributo             varchar2(30)
                                          , valor                varchar2(255) );
--
   type t_tab_csf_subgrupo_pat_ff is table of tab_csf_subgrupo_pat_ff index by binary_integer;
   vt_tab_csf_subgrupo_pat_ff t_tab_csf_subgrupo_pat_ff;
--
--| Informa��es dos impostos dos subgrupos do patrimonio
   type tab_csf_imp_subgrupo_pat is record ( cd_grupopat       varchar2(10)
                                           , cd_subgrupopat    varchar2(10)
                                           , cd_tipo_imp       number(3)   
                                           , aliq              number(5,2) 
                                           , qtde_mes          number(3) );
--
   type t_tab_csf_imp_subgrupo_pat is table of tab_csf_imp_subgrupo_pat index by binary_integer;
   vt_tab_csf_imp_subgrupo_pat t_tab_csf_imp_subgrupo_pat;
--     
--| Informa��es Flex Field dos impostos dos subgrupos do patrimonio
   type tab_csf_imp_subgrupo_pat_ff is record ( cd_grupopat       varchar2(10)
                                              , cd_subgrupopat    varchar2(10)
                                              , cd_tipo_imp       number(3)
                                              , atributo          varchar2(30)
                                              , valor             varchar2(255));
--
   type t_tab_csf_imp_subgrupo_pat_ff is table of tab_csf_imp_subgrupo_pat_ff index by binary_integer;
   vt_tab_csf_imp_subgrupo_pat_ff t_tab_csf_imp_subgrupo_pat_ff;
--
--| Informa��es Flex Field dos bens do ativo imobilizado
   type tab_csf_bem_ativo_imob_ff is record ( cpf_cnpj      varchar2(14)
                                            , cod_ind_bem   varchar2(60)
                                            , atributo      varchar2(30)
                                            , valor         varchar2(255)
                                            );
--
   type t_tab_csf_bem_ativo_imob_ff is table of tab_csf_bem_ativo_imob_ff index by binary_integer;
   vt_tab_csf_bem_ativo_imob_ff t_tab_csf_bem_ativo_imob_ff;
--
--| Informa��es dos bens do ativo imobilizado
   type tab_csf_bem_ativo_imob is record ( cpf_cnpj       varchar2(14)
                                         , cod_ind_bem    varchar2(60)
                                         , dm_ident_merc  number(1)
                                         , descr_item     varchar2(255)
                                         , cod_prnc       varchar2(15)
                                         , cod_cta        varchar2(60)
                                         , nr_parc        number(3) );
--
   type t_tab_csf_bem_ativo_imob is table of tab_csf_bem_ativo_imob index by binary_integer;
   vt_tab_csf_bem_ativo_imob t_tab_csf_bem_ativo_imob;
--
--| Informa��es sobre a informa��o da utiliza��o do bem
   type tab_csf_util_bem is record ( cpf_cnpj      varchar2(14)
                                   , cod_ind_bem   varchar2(60)
                                   , cod_ccus      varchar2(60)
                                   , func          varchar2(255)
                                   , vida_util     number );
--
   type t_tab_csf_util_bem is table of tab_csf_util_bem index by binary_integer;
   vt_tab_csf_util_bem t_tab_csf_util_bem;
--
--| Informa��es sobre a informa��o da utiliza��o do bem
   type tab_csf_util_bem_ff is record ( cpf_cnpj      varchar2(14)
                                      , cod_ind_bem   varchar2(60)
                                      , cod_ccus      varchar2(60)
                                      , atributo      varchar2(30)
                                      , valor         varchar2(255));
--
   type t_tab_csf_util_bem_ff is table of tab_csf_util_bem_ff index by binary_integer;
   vt_tab_csf_util_bem_ff t_tab_csf_util_bem_ff;
--
--| Informa��es complementares dos bens do ativo imobilizado
   type tab_csf_bem_ativo_imob_comp is record ( cpf_cnpj            varchar2(14)
                                              , cod_ind_bem         varchar2(60)
                                              , cod_item            varchar2(60)
                                              , cod_grupopat        varchar2(10)
                                              , cod_subgrupopat     varchar2(10)
                                              , vida_util_fiscal    number(3)
                                              , vida_util_real      number(3)
                                              , dt_aquis            date
                                              , vl_aquis            number(15,2)
                                              , dt_ini_form         date
                                              , dt_fin_form         date
                                              , dm_deprecia         number(1)
                                              , dm_situacao         number(1)
                                              , dm_tipo_rec_pis     number(1)
                                              , dm_tipo_rec_cofins  number(1));
--
   type t_tab_csf_bem_ativo_imob_comp is table of tab_csf_bem_ativo_imob_comp index by binary_integer;
   vt_tab_csf_bem_ativo_imob_comp t_tab_csf_bem_ativo_imob_comp;
--
--| Informa��es Flex Field complementares dos bens do ativo imobilizado
   type tab_bem_ativo_imob_comp_ff is record ( cpf_cnpj            varchar2(14)
                                             , cod_ind_bem         varchar2(60)
                                             , atributo            varchar2(30)
                                             , valor               varchar2(255));
--
   type t_tab_bem_ativo_imob_comp_ff is table of tab_bem_ativo_imob_comp_ff index by binary_integer;
   vt_tab_bem_ativo_imob_comp_ff t_tab_bem_ativo_imob_comp_ff;
--
--| Informa��es sobre os documentos fiscais do bem
   type tab_csf_nf_bem_ativo_imob is record ( cpf_cnpj      varchar2(14)
                                            , cod_ind_bem   varchar2(60)
                                            , dm_ind_emit   number(1)
                                            , cod_part      varchar2(60)
                                            , cod_mod       varchar2(2) 
                                            , serie         varchar2(3) 
                                            , num_doc       number(9)   
                                            , chv_nfe_cte   varchar2(44)
                                            , dt_doc        date
                                            );
--
   type t_tab_csf_nf_bem_ativo_imob is table of tab_csf_nf_bem_ativo_imob index by binary_integer;
   vt_tab_csf_nf_bem_ativo_imob t_tab_csf_nf_bem_ativo_imob;
--
--| Informa��es sobre os documentos fiscais do bem
   type tab_csf_nf_bemativo_imob_ff is record ( cpf_cnpj      varchar2(14)
                                              , cod_ind_bem   varchar2(60)
                                              , dm_ind_emit   number(1)
                                              , cod_part      varchar2(60)
                                              , cod_mod       varchar2(2)
                                              , serie         varchar2(3)
                                              , num_doc       number(9)
                                              , atributo      varchar2(30)
                                              , valor         varchar2(255)
                                              );
--
   type t_tab_csf_nf_bemativo_imob_ff is table of tab_csf_nf_bemativo_imob_ff index by binary_integer;
   vt_tab_csf_nf_bemativo_imob_ff t_tab_csf_nf_bemativo_imob_ff;
--
--| Informa��es sobre os documentos fiscais do bem
   type tab_csf_itnf_bem_ativo_imob is record ( cpf_cnpj      varchar2(14)
                                              , cod_ind_bem   varchar2(60)
                                              , dm_ind_emit   number(1)
                                              , cod_part      varchar2(60)
                                              , cod_mod       varchar2(2)
                                              , serie         varchar2(3)
                                              , num_doc       number(9)
                                              , num_item      number
                                              , cod_item      varchar2(60)
                                              , vl_item       number(15,2)
                                              , vl_icms       number(15,2)
                                              , vl_bc_pis     number(15,2)
                                              , vl_bc_cofins  number(15,2)
                                              , vl_frete      number(15,2)
                                              , vl_icms_st    number(15,2) 
                                              );
--
   type t_tab_csf_itnf_bem_ativo_imob is table of tab_csf_itnf_bem_ativo_imob index by binary_integer;
   vt_tab_csf_itnf_bem_ativo_imob t_tab_csf_itnf_bem_ativo_imob;
--
--| Informa��es flex field sobre os documentos fiscais do bem
   type tab_itnf_bem_ativo_imob_ff is record ( cpf_cnpj      varchar2(14)
                                             , cod_ind_bem   varchar2(60)
                                             , dm_ind_emit   number(1)
                                             , cod_part      varchar2(60)
                                             , cod_mod       varchar2(2)
                                             , serie         varchar2(3)
                                             , num_doc       number(9)
                                             , num_item      number(3)
                                             , atributo      varchar2(30)
                                             , valor         varchar2(255)
                                             );
--
   type t_tab_itnf_bem_ativo_imob_ff is table of tab_itnf_bem_ativo_imob_ff index by binary_integer;
   vt_tab_itnf_bem_ativo_imob_ff t_tab_itnf_bem_ativo_imob_ff;
--
--| Informa��es sobre os impostos do bem
   type tab_csf_rec_imp_bem_ativo is record ( cpf_cnpj             varchar2(14)
                                            , cod_ind_bem          varchar2(60)
                                            , cd_tipo_imp          number(3)   
                                            , aliq                 number(5,2) 
                                            , qtde_mes             number(3)   
                                            , qtde_mes_real        number(3) );
--
   type t_tab_csf_rec_imp_bem_ativo is table of tab_csf_rec_imp_bem_ativo index by binary_integer;
   vt_tab_csf_rec_imp_bem_ativo t_tab_csf_rec_imp_bem_ativo;
--
--| Informa��es flex field sobre os impostos do bem
   type tab_csf_recimp_bem_ativo_ff is record ( cpf_cnpj             varchar2(14)
                                              , cod_ind_bem          varchar2(60)
                                              , cd_tipo_imp          number(3)
                                              , atributo             varchar2(30)
                                              , valor                varchar2(255));
--
   type t_tab_csf_recimp_bem_ativo_ff is table of tab_csf_recimp_bem_ativo_ff index by binary_integer;
   vt_tab_csf_recimp_bem_ativo_ff t_tab_csf_recimp_bem_ativo_ff;
--
--| Informa��es Flex Field da Natureza da Opera��o/Presta��o
   type tab_csf_nat_oper_ff is record ( cod_nat       varchar2(10)
                                      , atributo      varchar2(30)
                                      , valor         varchar2(255)
                                      );
--
   type t_tab_csf_nat_oper_ff is table of tab_csf_nat_oper_ff index by binary_integer;
   vt_tab_csf_nat_oper_ff t_tab_csf_nat_oper_ff;
--
--| Informa��es da Natureza da Opera��o/Presta��o
   type tab_csf_nat_oper is record ( cod_nat       varchar2(10)
                                   , descr_nat     varchar2(255) );
--
   type t_tab_csf_nat_oper is table of tab_csf_nat_oper index by binary_integer;
   vt_tab_csf_nat_oper t_tab_csf_nat_oper;
--
--| Informa��es Flex Field complementar do documento fiscal
   type tab_csf_inf_comp_dcto_fis_ff is record ( cod_infor  varchar2(10)
                                      , atributo      varchar2(30)
                                      , valor         varchar2(255) );
--
   type t_tab_csf_inf_comp_dcto_fis_ff is table of tab_csf_inf_comp_dcto_fis_ff index by binary_integer;
   vt_tab_csf_inf_comp_dcto_fi_ff t_tab_csf_inf_comp_dcto_fis_ff;
--
--| Informa��es complementar do documento fiscal
   type tab_csf_inf_comp_dcto_fis is record ( cod_infor  varchar2(10)
                                            , txt        varchar2(255) );
--
   type t_tab_csf_inf_comp_dcto_fis is table of tab_csf_inf_comp_dcto_fis index by binary_integer;
   vt_tab_csf_inf_comp_dcto_fis t_tab_csf_inf_comp_dcto_fis;
--
--| Informa��es de observa��es do lan�amento fiscal
   type tab_obs_lancto_fiscal_ff is record ( cod_obs       varchar2(6)
                                           , atributo      varchar2(30)
                                           , valor         varchar2(255) );
--
   type t_tab_obs_lancto_fiscal_ff is table of tab_obs_lancto_fiscal_ff index by binary_integer;
   vt_tab_obs_lancto_fiscal_ff t_tab_obs_lancto_fiscal_ff;
--
--| Informa��es de observa��es do lan�amento fiscal
   type tab_obs_lancto_fiscal is record ( cod_obs   varchar2(6)
                                        , txt       varchar2(255));
--
   type t_tab_obs_lancto_fiscal is table of tab_obs_lancto_fiscal index by binary_integer;
   vt_tab_obs_lancto_fiscal t_tab_obs_lancto_fiscal;
--
--| Informa��es do plano de contas cont�beis
   type tab_csf_plano_conta_ff is record ( cpf_cnpj     varchar2(14)
                                         , cod_cta      varchar2(255)
                                         , atributo  varchar2(30)
                                         , valor     varchar2(255) );
--
   type t_tab_csf_plano_conta_ff is table of tab_csf_plano_conta_ff index by binary_integer;
   vt_tab_csf_plano_conta_ff t_tab_csf_plano_conta_ff;
--
--| Informa��es do plano de contas cont�beis
   type tab_csf_plano_conta is record ( cpf_cnpj     varchar2(14)
                                      , cod_cta      varchar2(255)
                                      , dt_inc_alt   date
                                      , cod_nat_pc   varchar2(2)
                                      , dm_ind_cta   varchar2(1)
                                      , nivel        number(2)
                                      , cod_cta_sup  varchar2(255)
                                      , descr_cta    varchar2(255) );
--
   type t_tab_csf_plano_conta is table of tab_csf_plano_conta index by binary_integer;
   vt_tab_csf_plano_conta t_tab_csf_plano_conta;
--
--| Informa��es do plano de contas referencial
   type tab_csf_pc_referen is record ( cpf_cnpj     varchar2(14)
                                     , cod_cta      varchar2(255)
                                     , cod_ent_ref  varchar2(2)
                                     , cod_cta_ref  varchar2(30)
                                     , cod_ccus     varchar2(30) );
--
   type t_tab_csf_pc_referen is table of tab_csf_pc_referen index by binary_integer;
   vt_tab_csf_pc_referen t_tab_csf_pc_referen; 
--
--| Informa��es do plano de contas referencial por Periodo
   type tab_csf_pc_referen_period is record ( cpf_cnpj     varchar2(14)
                                            , cod_cta      varchar2(255)
                                            , cod_ent_ref  varchar2(2)
                                            , cod_cta_ref  varchar2(30)
                                            , cod_ccus     varchar2(30)
                                            , dt_ini       date
                                            , dt_fin       date);
--
   type t_tab_csf_pc_referen_period is table of tab_csf_pc_referen_period index by binary_integer;
   vt_tab_csf_pc_referen_period  t_tab_csf_pc_referen_period;
--
--| Informa��es do plano de contas referencial
   type tab_csf_pc_referen_ff is record ( cpf_cnpj     varchar2(14)
                                        , cod_cta      varchar2(255)
                                        , cod_ent_ref  varchar2(2)
                                        , cod_cta_ref  varchar2(30)
                                        , cod_ccus     varchar2(30)
                                        , atributo     varchar2(30)
                                        , valor        varchar2(255));
--
   type t_tab_csf_pc_referen_ff is table of tab_csf_pc_referen_ff index by binary_integer;
   vt_tab_csf_pc_referen_ff t_tab_csf_pc_referen_ff;
--
--| Informa��es das subconta_correlata
   type tab_csf_subconta_correlata is record ( cpf_cnpj      varchar2(14)
                                             , cod_cta       varchar2(255)
                                             , cod_idt       varchar2(6)
                                             , cod_cta_corr  varchar2(255)
                                             , cd_natsubcnt  varchar2(2));
--
   type t_tab_csf_subconta_correlata is table of tab_csf_subconta_correlata index by binary_integer;
   vt_tab_csf_subconta_correlata  t_tab_csf_subconta_correlata;
--
--| Informa��es do de-para Plano de Contas e Aglutina��o Cont�bil Societ�ria    
   type tab_csf_pc_aglut_contabil is record ( cpf_cnpj_emit  varchar2(14)
                                            , cod_cta        varchar2(255)
                                            , cod_agl        varchar2(30)
                                            , cod_ccus       varchar2(30)
                                            );
--
   type t_tab_csf_pc_aglut_contabil is table of tab_csf_pc_aglut_contabil index by binary_integer;
   vt_tab_csf_pc_aglut_contabil     t_tab_csf_pc_aglut_contabil;
--
--| Informa��es de Aglutina��o Cont�bil Societ�ria
   type tab_csf_aglut_contabil is record ( cpf_cnpj_emit     varchar2(14)
                                         , cod_nat           varchar2(2)
                                         , cod_agl           varchar2(30)
                                         , descr_agl         varchar2(255)
                                         , nivel             number(2)
                                         , dm_ind_cta        varchar2(1)
                                         , ar_cod_agl        varchar2(30)/*varchar2(2)*/
                                         , dt_ini            date
                                         , dt_fin            date
                                         );
--
   type t_tab_csf_aglut_contabil is table of tab_csf_aglut_contabil index by binary_integer;
   vt_tab_csf_aglut_contabil     t_tab_csf_aglut_contabil;
--
--| Informa��es de centro de custos
   type tab_csf_centro_custo_ff is record ( cpf_cnpj    varchar2(14)
                                          , cod_ccus    varchar2(30)
                                          , atributo    varchar2(30)
                                          , valor       varchar2(255) );
--
   type t_tab_csf_centro_custo_ff is table of tab_csf_centro_custo_ff index by binary_integer;
   vt_tab_csf_centro_custo_ff t_tab_csf_centro_custo_ff;
--
--| Informa��es de centro de custos
   type tab_csf_centro_custo is record ( cpf_cnpj    varchar2(14)
                                       , cod_ccus    varchar2(30)
                                       , dt_inc_alt  date
                                       , descr_ccus  varchar2(255) );
--
   type t_tab_csf_centro_custo is table of tab_csf_centro_custo index by binary_integer;
   vt_tab_csf_centro_custo t_tab_csf_centro_custo;
--
--| Informa��es do hist�rico padr�o dos lan�amentos cont�beis
   type tab_csf_hist_padrao_ff is record ( cpf_cnpj    varchar2(14)
                                         , cod_hist    varchar2(30)
                                         , atributo    varchar2(30)
                                         , valor       varchar2(255));
--
   type t_tab_csf_hist_padrao_ff is table of tab_csf_hist_padrao_ff index by binary_integer;
   vt_tab_csf_hist_padrao_ff t_tab_csf_hist_padrao_ff;
--
--| Informa��es do hist�rico padr�o dos lan�amentos cont�beis
   type tab_csf_hist_padrao is record ( cpf_cnpj    varchar2(14)
                                      , cod_hist    varchar2(30)
                                      , descr_hist  varchar2(255) );
--
   type t_tab_csf_hist_padrao is table of tab_csf_hist_padrao index by binary_integer;
   vt_tab_csf_hist_padrao t_tab_csf_hist_padrao;
--
--| Procedimento integra os dados de Par�metros de C�lculo de ICMS-ST
   type tab_item_param_icmsst_ff is record ( cpf_cnpj    	        varchar2(14)
                                               , cod_item    	        varchar2(60)
                                               , sigla_uf_dest	        varchar2(2)
                                               , cfop_orig	        number(4)
                                               , dt_ini		        date
                                               , dt_fin		        date
                                               , atributo               varchar2(30)
                                               , valor                  varchar2(255));
--
   type t_tab_item_param_icmsst_ff is table of tab_item_param_icmsst_ff index by binary_integer;
   vt_tab_item_param_icmsst_ff t_tab_item_param_icmsst_ff;
--
--| Procedimento integra os dados de Par�metros de C�lculo de ICMS-ST
   type tab_csf_item_param_icmsst is record ( cpf_cnpj    	  varchar2(14)
                                            , cod_item    	  varchar2(60)
                                            , sigla_uf_dest	  varchar2(2)
                                            , cfop_orig		  number(4)
                                            , dm_mod_base_calc_st number(1)
                                            , dt_ini		  date
                                            , dt_fin		  date
                                            , aliq_dest		  number(5,2)
                                            , cod_obs		  varchar2(6)
                                            , cfop_dest		  number(4)
                                            , cod_st		  varchar2(2)
                                            , indice		  number(10,4)
                                            , perc_reduc_bc	  number(5,2)
                                            , dm_ajusta_mva	  number(1)
                                            , dm_efeito		  number(1) );
--
   type t_tab_csf_item_param_icmsst is table of tab_csf_item_param_icmsst index by binary_integer;
   vt_tab_csf_item_param_icmsst t_tab_csf_item_param_icmsst;
   
--| Informa��es de Complemento do item
   type tab_csf_item_compl is record ( cpf_cnpj               varchar2(14)
                                     , cod_item	              varchar2(60)
                                     , csosn                  varchar2(3)
                                     , cst_icms	              varchar2(3)
                                     , per_red_bc_icms	      number(6,2)
                                     , bc_icms_st             number(6,2)
                                     , cst_ipi_entrada	      varchar2(2)
                                     , cst_ipi_saida          varchar2(2)
                                     , aliq_ipi	              number(6,2)
                                     , cst_pis_entrada	      varchar2(2)
                                     , cst_pis_saida          varchar2(2)
                                     , nat_rec_pis            varchar2(3)
                                     , aliq_pis	              number(6,2)
                                     , cst_cofins_entrada     varchar2(2)
                                     , cst_cofins_saida	      varchar2(2)
                                     , nat_rec_cofins	      varchar2(3)
                                     , aliq_cofins	      number(6,2)
                                     , aliq_iss	              number(6,2)
                                     , cod_cta	              varchar2(25)
                                     , observacao             varchar2(60)
                                     , vl_est_venda           number(7,2)
                                     );
--
   type t_tab_csf_item_compl is table of tab_csf_item_compl index by binary_integer;
   vt_tab_csf_item_compl t_tab_csf_item_compl;
--

--| Controle de Vers�o Cont�bil
   type tab_csf_ctrl_ver_contab is record ( cpf_cnpj_emit   varchar2(14)
                                          , cd              varchar2(10)
                                          , descr           varchar2(50)
                                          , dm_tipo         number(1)
                                          , dt_ini          date
                                          , dt_fin          date
                                          );
--
   type t_tab_csf_ctrl_ver_contab is table of tab_csf_ctrl_ver_contab index by binary_integer;
   vt_tab_csf_ctrl_ver_contab t_tab_csf_ctrl_ver_contab;

-- Item Componente/Insumo - Bloco K - Sped Fiscal
   type tab_csf_item_insumo is record ( cpf_cnpj_emit   varchar2(14)
                                      , cod_item        varchar2(60)
                                      , cod_item_comp   varchar2(60)
                                      , qtd_comp        number(17,6)
                                      , perda           number(5,2)
                                      );
--
   type t_tab_csf_item_insumo is table of tab_csf_item_insumo index by binary_integer;
   vt_tab_csf_item_insumo t_tab_csf_item_insumo;
--
--| Retorno dos dados da Abertura do FCI

 type tab_abertura_fci is record ( cnpj_empr                varchar2(14)
                                 , mes_ref                  varchar2(2)
                                 , ano_ref                  number(4)
                                 , nro_prot                 varchar2(10)
                                 );
--
 type t_tab_abertura_fci   is table of tab_abertura_fci index by binary_integer;
 vt_tab_abertura_fci       t_tab_abertura_fci;
--
--| Retorno dos dados do FCI
 type tab_retorno_fci is record ( cnpj_empr                varchar2(14)
                                , mes_ref                  varchar2(2)
                                , ano_ref                  number(4)
                                , cod_item                 varchar2(60)
                                , coef_import              number(6,2)
                                , nro_fci                  varchar2(36)
                                , vl_saida                 number(7,2)
                                , vl_entr_tot              number(8,2)
                                );
--
 type t_tab_retorno_fci   is table of tab_retorno_fci index by binary_integer;
 vt_tab_retorno_fci       t_tab_retorno_fci;
--
--| Processo de leitura dos Par�metros DE-PARA de Item de Fornecedor para Emp. Usu�ria
  type tab_csf_param_item_entr is record ( cpf_cnpj_emit  varchar2(14)
                                         , cnpj_orig      varchar2(14)
                                         , cod_ncm_orig   varchar2(8)
                                         , cod_item_orig  varchar2(60)
                                         , cod_item_dest  varchar2(60)
                                         );
  --
  type t_tab_csf_param_item_entr is table of tab_csf_param_item_entr index by binary_integer;
  vt_tab_csf_param_item_entr t_tab_csf_param_item_entr;
--
--| Par�metros de convers�o de nfe
  type tab_param_oper_fiscal_entr is record ( cpf_cnpj_emit      varchar2(14)
                                            , cfop_orig          number(4)
                                            , cnpj_orig          varchar2(14)
                                            , dm_raiz_cnpj_orig  number(1)
                                            , cod_ncm_orig       varchar2(8)
                                            , cod_item_orig      varchar2(60)
                                            , cod_st_icms_orig   varchar2(3)
                                            , cod_st_ipi_orig    varchar2(2)
                                            , cfop_dest          number(4)
                                            , dm_rec_icms        number(1)
                                            , cod_st_icms_dest   varchar2(3)
                                            , dm_rec_ipi         number(1)
                                            , cod_st_ipi_dest    varchar2(2)
                                            , dm_rec_pis         number(1)
                                            , cod_st_pis_dest    varchar2(2)
                                            , dm_rec_cofins      number(1)
                                            , cod_st_cofins_dest varchar2(2)
                                            );
  --
  type t_tab_param_oper_fiscal_entr is table of tab_param_oper_fiscal_entr index by binary_integer;
  vt_tab_param_oper_fiscal_entr t_tab_param_oper_fiscal_entr;
--
   type tab_param_dipamgia is record ( cpf_cnpj          varchar2(14)
                                     , ibge_estado       varchar2(2)
                                     , cd_dipamgia       varchar2(10)
                                     , cd_cfop           number(4)
                                     , cod_item          varchar2(60)
                                     , cod_ncm           varchar2(8)
                                     , perc_rateio_item  number(5,2)
                                     );
--
  type t_tab_param_dipamgia is table of tab_param_dipamgia index by binary_integer;
   vt_tab_param_dipamgia t_tab_param_dipamgia;
--
   type tab_param_dipamgia_ff is record ( cpf_cnpj          varchar2(14)
                                        , ibge_estado       varchar2(2)
                                        , cd_dipamgia       varchar2(10)
                                        , cd_cfop           number(4)
                                        , cod_item          varchar2(60)
                                        , cod_ncm           varchar2(8)
                                        , atributo          varchar2(30)
                                        , valor             varchar2(255)
                                        );
--
   type t_tab_param_dipamgia_ff is table of tab_param_dipamgia_ff index by binary_integer;
   vt_tab_param_dipamgia_ff  t_tab_param_dipamgia_ff;
--
   type tab_proc_adm_efd_reinf is record ( cpf_cnpj                varchar2(14)
                                         , dm_tp_proc              number(1)
                                         , nro_proc                varchar2(21)
                                         , dt_ini                  date
                                         , dt_fin                  date
                                         , ibge_cidade             varchar2(7)
                                         , cod_ident_vara          varchar2(4)
                                         , dm_ind_auditoria        number(1)
                                         , dm_reinf_legado         number(1)
                                         );
--
   type t_tab_proc_adm_efd_reinf is table of tab_proc_adm_efd_reinf index by binary_integer;
   vt_tab_proc_adm_efd_reinf t_tab_proc_adm_efd_reinf;
--
  type tab_proc_adm_efd_reinf_ff is record ( cpf_cnpj                varchar2(14)
                                            , dm_tp_proc                 number(1)
                                            , nro_proc                   varchar2(21)
                                            , atributo                   varchar2(30)
                                            , valor                      varchar2(255)
                                            );
--
   type t_tab_proc_adm_efd_reinf_ff is table of tab_proc_adm_efd_reinf_ff index by binary_integer;
   vt_tab_proc_adm_efd_reinf_ff t_tab_proc_adm_efd_reinf_ff;
--
   type tab_procadmefdreinfinftrib is record ( cpf_cnpj                   varchar2(14)
                                             , dm_tp_proc                 number(1)
                                             , nro_proc                   varchar2(21)
                                             , cod_susp                   number(14)
                                             , cd_ind_susp_exig           varchar2(2)
                                             , dt_decisao                 date
                                             , dm_ind_deposito            varchar2(1)
                                             );
--
   type t_tab_procadmefdreinfinftrib is table of tab_procadmefdreinfinftrib index by binary_integer;
   vt_tab_procadmefdreinfinftrib t_tab_procadmefdreinfinftrib;
--
-------------------------------------------------------------------------------------------------------

   gv_sql varchar2(4000) := null;

-------------------------------------------------------------------------------------------------------

   gv_aspas           char(1) := null;
   gv_nome_dblink     empresa.nome_dblink%type := null;
   gv_owner_obj       empresa.owner_obj%type := null;
   gv_formato_dt_erp  empresa.formato_dt_erp%type := null;

-------------------------------------------------------------------------------------------------------

-- Declara��o de constantes

   erro_de_validacao  constant number := 1;
   erro_de_sistema    constant number := 2;
   informacao         constant number := 35;

-------------------------------------------------------------------------------------------------------

   gv_cabec_log       Log_Generico_Cad.mensagem%TYPE;
   gv_cabec_log_item  Log_Generico_Cad.mensagem%TYPE;
   gv_mensagem_log    Log_Generico_Cad.mensagem%TYPE;
   gv_obj_referencia  Log_Generico_Cad.obj_referencia%type default null;
   gn_referencia_id   Log_Generico_Cad.referencia_id%type := null;
   gv_cd_obj          obj_integr.cd%type := '1';
   gn_multorg_id      mult_org.id%type;
   gv_multorg_cd      mult_org.cd%type;
   gn_empresa_id      empresa.id%type;
   gv_sistema_em_nuvem varchar2(10);
   gv_formato_data       param_global_csf.valor%type := null;

-------------------------------------------------------------------------------------------------------
-- Procedimento Par�metros de Convers�o de NFe
procedure pkb_ler_oper_fiscal_ent(ev_cpf_cnpj in varchar2);

-- Processo de leitura dos Par�metros DE-PARA de Item de Fornecedor para Emp. Usu�ria
procedure pkb_ler_item_fornc_eu ( ev_cpf_cnpj in varchar2);

-- Processo de leitura do Retorno dos dados da Ficha de Conteudo de Importa��o
procedure pkb_ler_retorno_fci ( est_log_generico     in out nocopy dbms_sql.number_table
                              , en_aberturafciarq_id in            abertura_fci_arq.id%type
                              , ev_cnpj_empr         in            varchar2
                              , ev_mes_ref           in            varchar2
                              , en_ano_ref           in            number
                              );

-- Processo que ira ler todos os registros da VW_CSF_RETORNO_FCI
procedure pkb_legado_fci ( ev_cpf_cnpj in varchar2 );

--| Procedimento de integra��o do Item Componente/Insumo - Bloco K - Sped Fiscal
--procedure pkb_item_insumo ( ev_cpf_cnpj in  varchar2 );

--| Procedimento de integra��o do Controle de Vers�o Cont�bil
procedure pkb_ctrl_ver_contab ( ev_cpf_cnpj in  varchar2 );

--| Procedimento de integra��o Flex Field do Hist�rico Padr�o
procedure pkb_hist_padrao_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                            , ev_cpf_cnpj        in  varchar2
                            , ev_cod_hist       in  varchar2
                            , sn_multorg_id     in out mult_org.id%type);

--| Procedimento de integra��o do Hist�rico Padr�o
procedure pkb_hist_padrao ( ev_cpf_cnpj in  varchar2 );

--| Procedimento de integra��o Flex Field do centro de custo
procedure pkb_centro_custo_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                             , ev_cpf_cnpj        in  varchar2
                             , ev_cod_ccus        in  varchar2
                             , sn_multorg_id      in out mult_org.id%type);

--| Procedimento de integra��o do centro de custo
procedure pkb_centro_custo ( ev_cpf_cnpj in  varchar2 );

--| Procedimento de integra��o Flex Field do plano de contas
procedure pkb_plano_conta_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                            , ev_cpf_cnpj       in  varchar2
                            , ev_cod_cta        in  varchar2
                            , sn_multorg_id     in out mult_org.id%type);

--| Procedimento de integra��o do plano de contas
procedure pkb_plano_conta ( ev_cpf_cnpj in  varchar2 );

--| Procedimento de integra��o de Observa��o do Lan�amento Fiscal
procedure pkb_obs_lancto_fiscal_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                                  , ev_cod_obs        in  varchar2
                                  , sn_multorg_id     in out mult_org.id%type);

--| Procedimento de integra��o de Observa��o do Lan�amento Fiscal
procedure pkb_obs_lancto_fiscal;

--| Procedimento de integra��o Flex Field de informa��es complementar do documento fiscal
procedure pkb_infor_comp_dcto_fiscal_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                                       , ev_cod_infor      in  varchar2
                                       , sn_multorg_id     in out mult_org.id%type);

--| Procedimento de integra��o de informa��es complementar do documento fiscal
procedure pkb_inf_comp_dcto_fis;

--| Procedimento de integra��o Flex Field de Natureza da Opera��o
procedure pkb_nat_oper_ff( est_log_generico  in    out nocopy  dbms_sql.number_table
                         , ev_cod_nat        in  varchar2
                         , sn_multorg_id     in out mult_org.id%type);

--| Procedimento de integra��o de Natureza da Opera��o
procedure pkb_nat_oper;

--| Procedimento de integra��o de dados Flex Field dos Grupos de Patrimonio
procedure pkb_grupo_pat_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                          , ev_cd             in  varchar2
                          , sn_multorg_id     in out mult_org.id%type);

--| Procedimento de integra��o dos Grupos de Patrimonio
procedure pkb_grupo_pat ( ev_cpf_cnpj in varchar2 );

--| Procedimento de integra��o Flex Field de Bens do ativo Imobilizado
procedure pkb_bem_ativo_imob_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                               , ev_cpf_cnpj       in  varchar2
                               , ev_cod_ind_bem    in  varchar2
                               , sn_multorg_id     in out mult_org.id%type);

--| Procedimento de integra��o de Bens do ativo Imobilizado
procedure pkb_bem_ativo_imob ( ev_cpf_cnpj in varchar2 );

--| Procedimento de integra��o Flex Field de Item (Produtos/Servi�os)
procedure pkb_item_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                     , ev_cpf_cnpj       in  varchar2
                     , ev_cod_item       in  varchar2
                     , sn_multorg_id     in out mult_org.id%type);

--| Procedimento de integra��o de Item (Produtos/Servi�os)
procedure pkb_item ( ev_cpf_cnpj in varchar2 );

--| Procedimento de integra��o de campos FlexField de Unidade
procedure pkb_unidade_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                        , ev_sigla_unid     in  varchar2
                        , sn_multorg_id     in out mult_org.id%type);

--| Procedimento de integra��o de Unidades de Medidas
procedure pkb_unidade;

--| Procedimento de integra��o de Pessoa
procedure pkb_pessoa;

--| Procedimento de integra��o de campos FlexField de Pessoa
procedure pkb_pessoa_ff( est_log_generico in out nocopy  dbms_sql.number_table
                       , ev_cod_part      in varchar2
                       , sn_multorg_id    in out mult_org.id%type
                       , sv_cod_nif       in out pessoa.cod_nif%type );

--| Procedimento integra os dados Flex Field de Par�metros de C�lculo de ICMS-ST
procedure pkb_item_param_icmsst_ff( est_log_generico    in  out nocopy  dbms_sql.number_table
                                  , ev_cpf_cnpj         varchar2
                                  , ev_cod_item         varchar2
                                  , ev_sigla_uf_dest    varchar2
                                  , en_cfop_orig        number
                                  , ed_dt_ini           date
                                  , ed_dt_fin           date
                                  , sn_multorg_id       in out mult_org.id%type);

--| Procedimento integra os dados de Par�metros de C�lculo de ICMS-ST
procedure pkb_item_param_icmsst ( ev_cpf_cnpj  in  varchar2 );

-------------------------------------------------------------------------------------------------------

--| Procedimento que inicia a integra��o de cadastros
procedure pkb_integracao ( en_empresa_id  in  empresa.id%type
                         , ed_dt_ini      in  date
                         , ed_dt_fin      in  date
                         , en_nro_linha   in  number default 1 --#68800 
                         );

-------------------------------------------------------------------------------------------------------------------------------

--| Procedimento que inicia a integra��o de cadastros Normal, com todas as empresas

procedure pkb_integracao_normal ( en_multorg_id in mult_org.id%type
                                , ed_dt_ini     in  date
                                , ed_dt_fin     in  date
                                );

-------------------------------------------------------------------------------------------------------

-- Processo de integra��o informando todas as empresas matrizes
procedure pkb_integr_cad_geral ( en_multorg_id in mult_org.id%type
                               , ed_dt_ini     in  date
                               , ed_dt_fin     in  date
                               );

-------------------------------------------------------------------------------------------------------

-- Processo de integra��o informando todas as empresas matrizes
procedure pkb_integr_empresa_geral ( en_paramintegrdados_id in param_integr_dados.id%type 
                                   , en_empresa_id          in empresa.id%type
                                   );

-------------------------------------------------------------------------------------------------------

end pk_int_view_cad;
/
