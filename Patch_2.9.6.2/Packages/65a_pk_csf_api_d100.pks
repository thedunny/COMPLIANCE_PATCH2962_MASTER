create or replace package csf_own.pk_csf_api_d100 is

----------------------------------------------------------------------------------------------------------
-- Especificação do pacote de procedimentos de integração e validação do Registro D100.
----------------------------------------------------------------------------------------------------------
--
-- Em 28/01/2021   - Karina de Paula
-- Redmine #75607  - Ajustes na rotina de integração do CTe
-- Rotina Alterada - pkb_integr_ct_d100    => Retirado o delete da log_generico_ct e incluído na pkb_excluir_dados_ct
--                 - pkb_excluir_dados_ct  => Incluído o delete da log_generico_ct e incluído o parâmetro de entrada en_excl_rloteintwsct
-- Liberado        - Release_2.9.7, Patch_2.9.6.2 e Patch_2.9.5.5
--
-- Em 12/01/2021 - Eduardo Linden
-- Redmine #75121 (Feedback) - Inclusão de parametrização para preenchimento do Codigo do Tipo Serviço Reinf para CTE modelo 67
-- Remoção cod_part da pesquisa do parametro e inclusão do campo empresa_id.
-- Rotinas alteradas - pkb_integr_ctimpretefd
-- Patch_2.9.5.4 / Patch_2.9.6.1 / Release_2.9.7
--
-- Em 11/01/2021 - Eduardo Linden
-- Redmine #74968 - Inclusão de parametrização para preenchimento do Codigo do Tipo Serviço Reinf para CTE modelo 67
-- Rotina alterada - pkb_integr_ctimpretefd => Inclusão de preenchimento do Código do Tipo Serviço Reinf a partir da parametrização da tabela aliq_tipoimp_ncm_empresa]
-- Patch_2.9.5.4 / Patch_2.9.6.1 / Release_2.9.7
--
-- Em 28/12/2020 - Eduardo Linden
-- Redmine #74671 - Inclusão do Flexfield UNID_ORG - VW_CSF_CONHEC_TRANSP_EFD_FF
-- Rotina alterada - pkb_integr_conhec_transp_ff => Inclusao do Flex Field UNID_ORG de Conhecimento de transporte 
--                 - pkb_integr_ct_d100 => Inclusao do parametro de entrada ev_cd_unid_org e a consistencia para o campo unidorg_id
--
-- Em 27/10/2020 - Renan Alves
-- Redmine #72827 - Validação para ct-e de complemento de valores
-- Foi incluido uma verificação no DM_IND_EMIT e realizado uma tratativa para cada DM_IND_EMIT
-- Rotina: pkb_integr_ct_d100
-- Patch_2.9.5.2 / Patch_2.9.4.5 / Release_2.9.6 
--
-- Em 15/10/2020 - Renan Alves
-- Redmine #72265 - CTe Integrado não valida
-- Foi incluido uma verificação no DM_IND_EMIT e realizado uma tratativa para cada DM_IND_EMIT
-- Rotina: pkb_integr_ctcompdoc_pisefd,
--         pkb_integr_ctcompdoc_cofinsefd 
--
-- Em 18/09/2020   - Luis Marques - 2.9.5
-- Redmine #70848  - Implementar Diferencial de Alíquota para CTE - Aviva
-- Nova Rotina     - pkb_integr_ct_dif_aliq - Procedimento para integração dos valores referente ao diferencial de
--                   aliquota.
-- Rotina Alterada - pkb_excluir_dados_ct - Incluido tabela "ct_dif_aliq".  
--
-- Em 19/08/2020   - Luis Marques - 2.9.3-5 / 2.9.4-2 / 2.9.5
-- Redmine #70694  - colocar a tabela CONHEC_TRANSP_IMP_RET na rotina de exclusão
-- Rotina Alterada - pkb_excluir_dados_ct - Incluir tabela "CONHEC_TRANSP_IMP_RET" na rotina de exclusão dos CTE(s).
--
-- Em 12/03/2020 - Luis Marques - 2.9.2-3 / 2.9.3
-- Redmine #65945 - Erro persiste
-- Rotina Alterada: pkb_valida_ct_d100 - alterado validação para tratar data como caracter para não impactar nao
--                  formatação do blanco do cliente.
--
-- Em 10/03/2020 - Luis Marques - 2.9.2-3 / 2.9.3
-- Redmine #65667 - Erro na pkb_valida_ct_d100.pkb_valida_ct_d100 fase(2): ORA-01843: not a valid month (ALTA)
-- Rotina Alterada: pkb_valida_ct_d100 - Tirado format no cursor da data e colocado format na variável destino.
-- 
-- Em 06/03/2020 - Allan Magrini
-- Redmine #65647 - CTe validando operação com base no participante novamente.. 
-- Colocada regra de validação na fase 1 se os campos vv_uf_emit = 'XX' or vv_uf_dest = 'XX' pega os valores de sigla da forma antiga e se
-- este campos vieram com siglas de estado diferente de XX mantem as mesmas e valida.        
-- Novas Rotinas: PKB_VALIDA_CFOP_POR_PART
-- Liberado na versão - Release_2.9.3, Patch_2.9.2.3 e Patch_2.9.1.6  
--
-- Em 05/12/2019 - Allan Magrini
-- Redmine #61656 - Regra de validação D100 campo 11
-- Criada regra de validação onde o campo CONHEC_TRANSP.DT_HR_EMISSAO>= 01/01/2019 e CONHEC_TRANSP.MODFISCAL_ID seja igual a 07, 09, 10, 11, 26 ou 27 
-- sera gerado erro de validação informando que o modelo selecionado não está mais vigente na data de emissão informada.        
-- RotinaS Criada: pkb_valida_ct_d100
--
-- Em 18/11/2019 - Allan Magrini
-- Redmine #60889 - CTe validando operação com base no participante. 
-- Alterado a origem do campo vv_uf_dest para o campo sigla_uf_fim da tabela conhec_transp       
-- Novas Rotinas: PKB_VALIDA_CFOP_POR_PART
--
-- Em 26/09/2019 - Luis Marques
-- Redmine #59148 - Construção de inclusão dos dados do emitente para Open Interface
-- Rotina Alterada: pkb_reg_pessoa_emit_ct - Ajuste para não jogar nulo no cnpj caso não encontre para
--                  ser posteriormente cadastrado.
--
-- Em 23/09/2019 - Luis Marques
-- Redmine #48353 - Ao fazer upload do CTe pelo compliance, o participante não é Cadastrado/Atulizado.
-- Novas Rotinas: pkb_integr_conhec_transp_emit e pkb_reg_pessoa_emit_ct para integração de dados do emitente.
--
-- Em 21/08/2019 - Luis Marques
-- Redmine #57141 - Validação nota fiscal serviços
-- RotinaS Alteradas: pkb_integr_ctcompdoc_pisefd E pkb_integr_ctcompdoc_cofinsefd - ajustado para mostrar Informação Geral ao inves de
--                    Avisos Genéricos
--
-- Em 08/08/2019 - Luis Marques
-- Redmine #57310 - CTE terceiros com erro ao informar cidade origem
-- Rotina Alterada: pkb_integr_conhec_transp_ff
--                  Retirada validação final colocada que verificava conteudo dos campos no final pois o conhecimento
--                  entra com valores default e a verificação na integração já está verificando a existencia dos campos.
--
-- Em 06/08/2019 - Luis Marques
-- Redmine #56568 - Mensagem de erro de validação para CT-e sem origem e destino
-- Rotina Alterada: pkb_integr_conhec_transp_ff
--                  Validação dos campos IBGE_CIDADE_INI, DESCR_CIDADE_INI, SIGLA_UF_INI, IBGE_CIDADE_FIM, DESCR_CIDADE_FIM
--                  SIGLA_UF_FIM estão sendo informados.
--
-- Em 29/07/2019 - Luis Marques
-- Redmine #56849 - feed - CT-e continua com erro de validação
-- Rotina Alterada: PKB_VALIDA_CFOP_POR_PART
--                  Na validação de CFOP estava passando informacao e esse tipo de log está como erro e será ajustadado
--                  para informação e nesta validação foi passado ERRO_DE_VALIDACAO.
--
-- Em 26/07/2019 - Luis Marques
-- Redmine #56729 - feed - CT-e e NFS-e ainda ficam com erro de validação
-- Rotina Alterada: pkb_validar
--                  Ajuistado para se contiver só aviso er informação na deixa o conhecimento como não validado
--   
-- Em 21/07/2019 - Luis Marques
-- Redmine #56565 - feed - Mensagem de ADVERTENCIA está deixando documento com ERRO DE VALIDAÇÂO
-- Rotinas alteradas: pkb_integr_ctcompdoc_pisefd, pkb_integr_ctcompdoc_pisefd e pkb_validar
--                    Alterado para colocar verificação de falta de Codigo de base de calculo de PIS/COFINS
--                    como advertencia.
--
-- Em 15/07/2019 - Luis Marques
-- Redmine #27836 Validação PIS e COFINS - Gerar log de advertência durante integração dos documentos
-- Rotinas alteradas: Incluido verificação de advertencia da falta de Codigo da base de calculo do credito
--                    se existir base e aliquota de imposto for do tipo imposto (0) e cliente juridico
--                    pkb_integr_ctcompdoc_pisefd e pkb_integr_ctcompdoc_pisefd
-- Function nova: fkg_dmindemit_conhectransp
--
-- Em 11/07/2019 - Luis MArques
-- Redmine #56155 - feed - Validação de chave de CT-e
-- RotinaS Alteradas: pkb_integr_ct_d100 e pkb_validar, recuperando forma de emissao da chave do conhecimento
--                    para ver se valida ou não a chave
--
-- Em 05/07/2019 - Luis Marques
-- Redmine #56042 - Parou de validar a chave de cte de terceiro
-- Rotinas Alteradas: pkb_integr_ct_d100 e pkb_validar na chamada da fkg_ret_valid_integr incluido campos
--                    dm_forma_emiss para validação de forma de emissão <> 8 8 e conhecimento 
--                    não de terceiros, DM_IND_EMIT = 0 e legado (1,2,3,4), DM_LEGADO in (1,2,3,4)
--
-- Em 05/06/2019 - Karina de Paula
-- Redmine #55008 - feed - está validando a forma de emissão 8
-- Rotina Alterada: pkb_integr_ct_d100 e pkb_validar => Incluída a chamada da pk_csf_ct.fkg_ret_valid_integr =. Function retorna se o dado de integração deve ser validado ou não
--
--
-- === AS ALTERAÇÕES ABAIXO ESTÃO NA ORDEM CRESCENTE USADA ANTERIORMENTE ================================================================================= --
--
--| Em 06/03/2012 - Angela Inês.
--| Incluído processo de validação (pkb_consiste_cte) para os complementos das operações de PIS e COFINS.
--
--| Em 18/05/2012 - Angela Inês.
--| Correção em mensagens e comentários de dados nas rotinas: pkb_integr_ctcompdoc_pisefd e pkb_integr_ctcompdoc_cofinsefd.
--| Verificar se o processo está considerando as CST corretas para os impostos PIS e COFINS.
--
--| Em 05/07/2012 - Angela Inês.
--| 1) Inclusão da rotina de geração de log/alterações nos processos de Conhecimento de Transporte (tabela: conhec_transp) - pkb_inclui_log_conhec_transp.
--| 2) Inclusão da exclusão dos dados de log/alteração dos processos de Conhecimento de Transporte (tabela: log_conhec_transp) - pkb_excluir_dados_ct.
--
--| Em 31/08/2012 - Angela Inês.
--| 1) Ficha HD: 62741 - Correção na validação de Natureza de Operação.
--|    Consistir se o identificador foi encontrado de acordo com o código informado no layout.
--
-- Em 28/11/2012 - Angela Inês.
-- Ficha HD 64674 - Melhoria em validações, não permitir valores zerados para os campos:
-- Rotina: pkb_integr_ct_d100 -> conhec_transp_vlprest.vl_prest_serv.
-- Rotina: pkb_integr_ct_d190 -> ct_reg_anal.vl_opr.
--
-- Em 19/12/2012 - Angela Inês.
-- Ficha HD 64591 - Implementar os campos flex field para a integração de Conhecimento de Transporte: ct_reg_anal.
--
-- Em 22/03/2013 - Angela Inês.
-- Ficha HD 64674 - Alterar a mensagem de validação do valor da operação retirando a palavra ICMS.
-- Rotina: pkb_integr_ct_d190.
--
-- Em 14/05/2013 - Angela Inês.
-- Incluir as tabelas faltantes para desprocessamento de conhecimento de transporte.
-- Rotina: pkb_excluir_dados_ct.
--
-- Em 26/07/2013 - Angela Inês.
-- Redmine #405 - Leiaute: Conhec. Transporte: Implementar no complemento de Pis/Cofins o código da natureza de receita isenta - Campos Flex Field.
-- Rotinas: pkb_integr_ctcompdocpisefd_ff e pkb_integr_ctcompdoccofefd_ff.
--
-- Em 06/08/2013 - Angela Inês.
-- Redmine #451 - Validação de informações Fiscais - Ficha HD 66733.
-- Correção nas rotinas chamadas pela pkb_consiste_cte, eliminando as referências das variáveis globais, pois essa rotina será chamada de outros processos.
-- Rotina: pkb_consiste_cte e todas as chamadas dentro dessa rotina.
-- Inclusão da função de validação dos conhecimentos de transporte, através dos processos de sped fiscal, contribuições e gias.
-- Rotina: fkg_valida_cte.
--
-- Em 05/09/2013 - Angela Inês.
-- Alterar a rotina que valida os processos considerando somente conhecimentos de transporte que sejam de terceiros (conhec_transp;dm_ind_emit = 1).
-- Rotina: fkg_valida_cte.
--
-- Em 13/09/2013 - Angela Inês.
-- Comentar a chamada da rotina de validação de documentos fiscais.
--
-- Em 19/09/2013 - Angela Inês.
-- Redmine #680 - Função de validação dos documentos fiscais.
-- Invalidar o conhecimento de transporte no processo de consistência dos dados, se o objeto de referência for CONHEC_TRANSP.
-- Rotina: pkb_consiste_cte.
--
-- Em 03/07/2014 - Angela Inês.
-- Redmine #3255 - Não está desprocessando a integração com a opção Conhecimento de Transporte.
-- As tabelas que faltavam no processo foram incluídas.
-- Rotina: pkb_excluir_dados_ct.
--
-- Em 19/02/2015 - Rogério Silva
-- Redmine #6398 - Validar CFOP x UF do Participante para Conhecimento de Transporte D100
-- Rotina: pkb_valida_cfop_por_part
--
-- Em 30/03/2015 - Angela Inês.
-- Redmine #6685 - Validação de Importação de Conhecimento de Transporte.
-- Implementar uma nova regra de validação de Conhecimento de Transporte, onde ao importar um Conhecimento de Transporte de Terceiro (D100) e o modelo for
-- "57-CTe", verificar se existe XML armazenado (DM_ARM_CTE_TERC=1) pela chave de acesso, caso a situação for "cancelada", gerar erro de validação para o
-- CTe de Terceiro.
-- Rotina: pkb_integr_ct_d100.
--
-- Em 09/04/2015 - Angela Inês.
-- Redmine #7489 - Erro de validação CT-e terceiro (TENDENCIA).
-- Considerar um registro para cada conhecimento de transporte e indicador de natureza do frete, ou seja, não poderá ter mais que um registro nas tabelas
-- ct_comp_doc_pis e ct_comp_doc_cofins com o mesmo conhecimento de transporte e indicador de natureza de frete.
-- Rotinas: pkb_valida_ct_d101 e pkb_valida_ct_d105.
--
-- Em 24/04/2015 - Angela Inês.
-- Redmine #7059 - Critério de escrituração base isenta e base outras (MANIKRAFT).
-- Ajustar o processo que determina a escrituração em base Isenta e Outras, da seguinte forma:
-- 1) CST ICMS = 50 ==>> Base Outras
-- 2) Para os itens que possuam CST de ICMS como 90, porém possuam o % de redução da base de cálculo, fazer o cálculo da redução, e lançar o valor como Isentas,
--    o restante do valor deverá ser escriturado como Outras.
-- Rotina: pkb_vlr_fiscal_ct_d100.
--
-- Em 04/05/2015 - Angela Inês.
-- Redmine #8004 - Erro de validação CT-e terceiro (TENDENCIA).
-- Correção: Ao verificar se existe imposto PIS com o mesmo CST e mesmo valor de base para COFINS, e de COFINS para PIS, considerar a CST, pois poderá existir mais de um registro com CSTs diferentes devido ao indicador da natureza de frete.
-- Rotinas: pkb_valida_ct_d101 e pkb_valida_ct_d105.
--
-- Em 01/06/2015 - Rogério Silva
-- Redmine #8230 - Processo de Registro de Log em Packages - Conhecimento de Transporte
--
-- Em 05/06/2015 - Angela Inês.
-- Redmine #8543 - Processos que utilizam as tabelas de códigos de ajustes para Apuração do ICMS.
-- Incluir como parâmetros de entrada as datas inicial e final para recuperar o ID do código de ocorrência de ajuste de apuração de icms.
-- Rotina: pkb_integr_ct_inf_prov.
--
-- Em 28/07/2015 - Angela Inês.
-- Redmine #9513 - Trocar a tabela de nota fiscal para conhecimento de transporte como referência ao campo dm_ind_emit.
--
-- Em 10/09/2015 - Angela Inês.
-- Redmine #11518 - Melhorar mensagem de CFOP no Registro Analítico - Conhecimento de Transporte.
-- A mensagem que indica: "CFOP informado no registro analítico está divergente para o participante do Conhecimento de Transporte", deverá ser melhorada
-- informando quais são os estados/uf do participante e do emitente do conhecimento, e o própria código da CFOP informado no registro analítico para validação.
-- Rotina: pkb_valida_cfop_por_part.
--
-- Em 11/12/2015 - Angela Inês.
-- Redmine #13461 - Acertar a recuperação dos valores de base de ICMS para Cupons Fiscais.
-- Para CST de ICMS 90-Outros, considerar base Outras por não houver redução de base de cálculo.
-- Rotina: pkb_vlr_fiscal_ct_d100.
--
-- Em 14/12/2015 - Rogério Silva
-- Redmine #13602 - Verificação ActionSys SBB - Conhec. Transp.
--
-- Em 17/12/2015 - Angela Inês.
-- Redmine #13793 - Correção na função que recupera valores contábeis para os Conhecimentos de Transporte.
-- Rotina: pkb_vlr_fiscal_ct_d100.
--
-- Em 05/02/2016 - Rogério Silva
-- Redmine #13079 - Registro do Número do Lote de Integração Web-Service nos logs de validação
--
-- Em 14/04/2016 - Fábio Tavares
-- Redmine #16793 - Melhoria nas mensagens dos processos flex-field.
--
-- Em 08/06/2016 - Angela Inês.
-- Redmine #19918 - Validação do CFOP - Conhecimento de Transporte.
-- Trocar a situação da mensagem de "erro de validação" para "informação geral".
-- Rotina: pkb_valida_cfop_por_part.
--
-- Em 03/02/2016 - Fábio Tavares.
-- Redmine #27380 - Revisão de processos de exclusão - BD
-- Foi adicionado a exclusão do registro da tabela de relacionamento R_CTRLINTEGRARQ_CT.
--
-- Em 20/11/2017 - Angela Inês.
-- Redmine #34618 - Utilizar o parâmetro: "Valida Cfop por Destinatário" do cadastro para empresa para Validar NFSe.
-- Melhoria na descrição da rotina que valida CFOP por Participante, no processo de validação de CTE/D100. O comentário da rotina PKB_VALIDA_CFOP_POR_PART, na
-- package PK_CSF_API_D100, está indicando que utiliza o parâmetro "Cfop por Destinatário" da empresa (Tabela empresa.dm_valida_cfop_por_dest), porém o processo
-- não utiliza esse parâmetro. Eliminamos do comentário da rotina essa informação. Melhoria técnica que não influencia nos processos.
--
-- Em 27/12/2017 - Angela Inês.
-- Redmine #37932 - Correção na validação dos dados do Conhecimento de Transporte - Inclusão.
-- Verificar nas rotinas que enviam dados para inclusão ou alteração do Conhecimento de Transporte (pk_csf_api_d100.pkb_integr_ct_d100), e acertar os valores que
-- possuem valores fixos considerando os valores enviados como parâmetros de entrada.
-- Rotinas: Conversão de CTE de Terceiros (PK_ENTR_CTE_TERCEIRO), Integração Open Interface (PK_INT_VIEW_D100), e Validação de Ambiente (PK_VLD_AMB_D100).
-- Rotina:pkb_integr_ct_d100.
--
-- Em 23/01/2018 - Karina de Paula
-- Redmine #38656 - Processos de integração de Conhecimento de Transporte - Modelo D100.
-- Incluido o modelo fiscal 67 nas rotinas que tratam o modelo 57
--
-- Em 25/04/2018 - Angela Inês.
-- Redmine #42169 - Correções: Registro C100 - Atualização do Plano de Contas; Conversão de CTE - CFOP.
-- O CFOP recuperado para atualizar o Código da Conta Contábil, é do Conhecimento de Transporte (conhec_transp.cfop_id).
-- Porém o processo de conversão de CTE considera o CFOP 1000, como valor inicial, e a rotina que gera os registros analíticos desse conhecimento (ct_reg_anal),
-- está utilizando o CFOP dos parâmetros de cálculo de ICMS da empresa (param_calc_icms_empr).
-- Rotina: pkb_integr_ct_d100.
--
-- Em 18/06/2018 - Karina de Paula
-- Redmine #40168 - Conversão de CTE e Geração dos campo COD_MUN_ORIG e COD_MUN_DEST no registro D100 do Sped de ICMS e IPI
-- Rotina Alterada: pkb_integr_conhec_transp_ff => Incluído novos atributos e validação: (IBGE_CIDADE_INI, DESCR_CIDADE_INI, SIGLA_UF_INI, IBGE_CIDADE_FIM, DESCR_CIDADE_FIM e SIGLA_UF_FIM)
-- Rotina Alterada: pkb_integr_ct_d100 => Incluído novos parâmetros de entrada na chamada da procedure, no update e no insert
--
-- Em 17/10/2018 - Karina de Paula
-- Redmine #47311 - Conversão de CT-e modelo 67
-- Rotina Criada: pkb_integr_ctimpret_inssefd => Procedimento integra os impostos retidos de INSS
--
-- Em 30/10/2018 - Karina de Paula
-- Redmine #47549 - Adaptar packages de integração
-- Rotina Criada: pkb_integr_ctimpretefd e pkb_integr_ctimpretefd_ff
--
-- Em 31/10/2018 - Karina de Paula
-- Redmine #47558 - Alterações na package pk_entr_cte_terceiro para atender INSS
-- Rotina Excluída: pkb_integr_ctimpret_inssefd (foi substituída pelas pkb_integr_ctimpretefd e pkb_integr_ctimpretefd_ff)
-- Rotina Alterada: pkb_integr_ct_d100 => Incluídos novos parâmetros de entrada dm_modal e dm_tp_serv
--
-- Em 05/11/2018 - Karina de Paula
-- Redmine #48410 - feed - nao está indo pra definitiva o CD_TP_SERV_REINF
-- Rotina Alterada: pkb_integr_ctimpretefd_ff => Alterada a verificação da variável vn_tiposervreinf_id (se "IS NULL" dar erro)
--
-- Em 06/11/2018 - Karina de Paula
-- Redmine #47561 - pk_csf_api_d100.pkb_integr_ct_imp_ret criar uma adivertência
-- Rotina Alterada: pkb_integr_ctimpretefd => Incluído msg de divergencia de valores de imposto para CTE de conversão
--
-- Em 13/11/2018 - Eduardo Linden
-- Redmine #49688 - Adequação do processo CTe de emissão própria para base isenta
-- O CTe receberá as tratativas de DE-PARA da base isenta (tabela param_calc_base_icms).
-- Rotina Alterada:pkb_vlr_fiscal_ct_d100
--
-- Em 29/01/2019 - Marcos Ferreira
-- Redmine #49524 - Funcionalidade - Base Isenta e Outros de Conhecimento de Transporte cuja emissão é própria
-- Solicitação: Unificar a procedure que retorna os valores fiscais (ICMS/ICMS-ST/IPI) de um conhecimento de transporte na api principal do Conhecimento de Transporte
-- Alterações: Transporte da procedure pk_csf_api_d100.pkb_vlr_fiscal_ct_d100 para pk_csf_ct.pkb_vlr_fiscal_ct
-- Procedures Alteradas: pkb_vlr_fiscal_ct
--
-- Em 29/01/2019 - Renan Alves
-- Redmine #49303 - Tela de Conhecimento de Transporte - Botão validar
-- Alteração: Foi acrescentado uma verificação para os tipos de emissões (0 - Emissão própria / 1 - Terceiros)
-- na pkb_consiste_cte, retornando uma mensagem de log específica, para cada emissão.
--
-- Em 26/02/2019 - Marcos Ferreira
-- Redmine #39016 - Integração e Validação do Campo conhec_transp.nro_chave_cte nas notas fiscais cuja emissão é por terceiro.
-- Solicitação: Corrir problema de validação de chave do CTe
-- Alterações: Incluído Validação e Geração da Chave CT-e
-- Procedures Alteradas: pkb_validar, pkb_integr_ct_d100
--
-- Redmine Redmine #53636 - Correção na validação da Chave de Acesso do CTe.
-- Ao validar a chave de acesso do CTe consistimos o CNPJ da chave de acesso com o CNPJ da Empresa emitente do Conhecimento de Transporte.
-- Passar a considerar o CNPJ da chave de acesso com o CNPJ da Empresa emitente do Conhecimento de Transporte desde que o Indicador do Emitente seja Emissão Própria.
-- Passar a considerar o CNPJ da chave de acesso com o CNPJ do Participante do Conhecimento de Transporte desde que o Indicador do Emitente seja Terceiro.
-- Rotinas: pkb_integr_ct_d100 e pkb_validar.
--
-- === AS ALTERAÇÕES PASSARAM A SER INCLUÍDAS NO INÍCIO DA PACKAGE ================================================================================= --
--
--------------------------------------------------------------------------------------------------------------------------------------------------
--
   gt_row_conhec_transp        conhec_transp%rowtype;
   gt_row_conhec_transp_emit   conhec_transp_emit%rowtype;
   gt_row_ct_reg_anal          ct_reg_anal%rowtype;
   gt_row_ct_compdoc_pisefd    ct_comp_doc_pis%rowtype;
   gt_row_ct_compdoc_cofinsefd ct_comp_doc_cofins%rowtype;
   gt_row_ct_procrefefd        ct_proc_ref%rowtype;
   gt_row_ctinfor_fiscal       ctinfor_fiscal%rowtype;
   gt_row_ct_inf_prov          ct_inf_prov%rowtype;
   gt_row_ct_impretefd         conhec_transp_imp_ret%rowtype;
   gt_row_ct_dif_aliq          ct_dif_aliq%rowtype;
--
-------------------------------------------------------------------------------------------------------

-- Declaração de constantes

   ERRO_DE_VALIDACAO       CONSTANT NUMBER := 1;
   ERRO_DE_SISTEMA         CONSTANT NUMBER := 2;
   CONHEC_TRANSP_INTEGRADO CONSTANT NUMBER := 34;
   INFORMACAO              CONSTANT NUMBER := 35;

-------------------------------------------------------------------------------------------------------

   gv_cabec_log          Log_Generico_ct.mensagem%TYPE;
   gv_cabec_log_item     Log_Generico_ct.mensagem%TYPE;
   gv_mensagem_log       Log_Generico_ct.mensagem%TYPE;
   gv_obj_referencia     Log_Generico_ct.obj_referencia%type default 'CONHEC_TRANSP';
   gn_referencia_id      Log_Generico_ct.referencia_id%type := null;
   gn_tipo_integr        number := null;
   gv_cd_obj             obj_integr.cd%type := '4';

-------------------------------------------------------------------------------------------------------

-- Retorna dm_st_proc através do id do conhecimento de transporte
function fkg_ct_dm_st_proc ( en_conhectransp_id in conhec_transp.id%type )
         return conhec_transp.dm_st_proc%type;
-------------------------------------------------------------------------------------------------------

--| Procedimento para excluir registros de conhecimento de transporte

procedure pkb_excluir_dados_ct ( en_conhectransp_id   in conhec_transp.id%type
                               , en_excl_rloteintwsct in number default 0 );

-------------------------------------------------------------------------------------------------------

--| Função retorna o ID do conhecimento de transporte se existir
function fkg_conhec_transp_id ( en_empresa_id    in empresa.id%type
                              , en_dm_ind_emit   in conhec_transp.dm_ind_emit%type
                              , en_dm_ind_oper   in conhec_transp.dm_ind_oper%type
                              , en_pessoa_id     in pessoa.id%type
                              , en_modfiscal_id  in mod_fiscal.id%type
                              , ev_serie         in conhec_transp.serie%type
                              , ev_subserie      in conhec_transp.subserie%type
                              , en_nro_ct        in conhec_transp.nro_ct%type )
         return conhec_transp.id%type;
-------------------------------------------------------------------------------------------------------

--| Procedimento seta o tipo de integração que será feito
-- 0 - Somente válida os dados e registra o Log de ocorrência
-- 1 - Válida os dados e registra o Log de ocorrência e insere a informação
-- Todos os procedimentos de integração fazem referência a ele
procedure pkb_seta_tipo_integr ( en_tipo_integr in number );

-------------------------------------------------------------------------------------------------------

--| Procedimento seta o objeto de referencia utilizado na Validação da Informação
procedure pkb_seta_obj_ref ( ev_objeto in varchar2 );

-------------------------------------------------------------------------------------------------------

procedure pkb_integr_ct_d100 ( est_log_generico            in out nocopy  dbms_sql.number_table
                             , ev_cpf_cnpj_emit            in             varchar2
                             , en_dm_ind_emit              in             conhec_transp.dm_ind_emit%type
                             , en_dm_ind_oper              in             conhec_transp.dm_ind_oper%type
                             , ev_cod_part                 in             pessoa.cod_part%type
                             , ev_cod_mod                  in             mod_fiscal.cod_mod%type
                             , ev_serie                    in             conhec_transp.serie%type
                             , ev_subserie                 in             conhec_transp.subserie%type
                             , en_nro_nf                   in             conhec_transp.nro_ct%type
                             , ev_sit_docto                in             sit_docto.cd%type
                             , ev_nro_chave_cte            in             conhec_transp.nro_chave_cte%type
                             , en_dm_tp_cte                in             conhec_transp.dm_tp_cte%type
                             , ev_chave_cte_ref            in             conhec_transp.chave_cte_ref%type
                             , ed_dt_emiss                 in             conhec_transp.dt_hr_emissao%type
                             , ed_dt_sai_ent               in             conhec_transp.dt_hr_emissao%type
                             , en_vl_doc                   in             conhec_transp_vlprest.vl_docto_fiscal%type
                             , en_vl_desc                  in             conhec_transp_vlprest.vl_desc%type
                             , en_dm_ind_frt               in             conhec_transp.dm_ind_frt%type
                             , en_vl_serv                  in             conhec_transp_vlprest.vl_prest_serv%type
                             , en_vl_bc_icms               in             conhec_transp_imp.vl_base_calc%type
                             , en_vl_icms                  in             conhec_transp_imp.vl_imp_trib%type
                             , en_vl_nt                    in             conhec_transp_imp.vl_imp_trib%type
                             , ev_cod_inf                  in             infor_comp_dcto_fiscal.cod_infor%type
                             , ev_cod_cta                  in             conhec_transp.cod_cta%type
                             , ev_cod_nat_oper             in             nat_oper.cod_nat%type
                             , en_multorg_id               in             mult_org.id%type
                             , sn_conhectransp_id          out            conhec_transp.id%type
                             , en_loteintws_id             in             lote_int_ws.id%type default 0
                             , en_cfop_id                  in             cfop.id%type default 1
                             , en_ibge_cidade_ini          in             conhec_transp.ibge_cidade_ini%type default 0
                             , ev_descr_cidade_ini         in             conhec_transp.descr_cidade_ini%type default 'XX'
                             , ev_sigla_uf_ini             in             conhec_transp.sigla_uf_ini%type default 'XX'
                             , en_ibge_cidade_fim          in             conhec_transp.ibge_cidade_fim%type default 0
                             , ev_descr_cidade_fim         in             conhec_transp.descr_cidade_fim%type default 'XX'
                             , ev_sigla_uf_fim             in             conhec_transp.sigla_uf_fim%type default 'XX'
                             , ev_dm_modal                 in             conhec_transp.dm_modal%type default '01'
                             , en_dm_tp_serv               in             conhec_transp.dm_tp_serv%type default 0
                             , ev_cd_unid_org              in             unid_org.cd%type default null
                             );

-------------------------------------------------------------------------------------------------------

-- Procedimento Integra as Informações relativas do Emitente do CT.
procedure pkb_integr_conhec_transp_emit ( est_log_generico           in out nocopy dbms_sql.number_table
                                        , est_row_conhec_transp_emit in out nocopy Conhec_Transp_Emit%rowtype
                                        , en_conhectransp_id         in            Conhec_Transp.id%TYPE 
                                        , ev_cod_part                in  pessoa.cod_part%TYPE );                    

------------------------------------------------------------------------------------------

-- Procedimento de Integração de Flex-Field de Conhecimento de Transporte
procedure pkb_integr_conhec_transp_ff ( est_log_generico    in out nocopy  dbms_sql.number_table
                                      , en_conhectransp_id  in             conhec_transp.id%type
                                      , ev_atributo         in             varchar2
                                      , ev_valor            in             varchar2 ); 
-------------------------------------------------------------------------------------------------------

--| Procedimento integra o resumo de impostos do Conhecimento de Transporte

procedure pkb_integr_ct_d190 ( est_log_generico            in out nocopy  dbms_sql.number_table
                             , est_ct_reg_anal             in out nocopy  ct_reg_anal%rowtype
                             , ev_cod_st                   in             cod_st.cod_st%type
                             , en_cfop                     in             cfop.cd%type
                             , ev_cod_obs                  in             obs_lancto_fiscal.cod_obs%type
                             , en_multorg_id               in             mult_org.id%type );

-------------------------------------------------------------------------------------------------------

--| Procedimento integra o resumo de impostos do Conhecimento de Transporte - Campos Flex Field

procedure pkb_integr_ct_d190_ff ( est_log_generico in out nocopy  dbms_sql.number_table
                                , en_ctreganal_id  in             ct_reg_anal.id%type
                                , ev_atributo      in             varchar2
                                , ev_valor         in             varchar2 );

-------------------------------------------------------------------------------------------------------

--| Procedimento integra o complemento da operação de PIS/PASEP - Campos Flex Field

procedure pkb_integr_ctcompdocpisefd_ff ( est_log_generico   in out nocopy  dbms_sql.number_table
                                        , en_ctcompdocpis_id in             ct_comp_doc_pis.id%type
                                        , ev_atributo        in             varchar2
                                        , ev_valor           in             varchar2
                                        , en_multorg_id      in             mult_org.id%type );

-------------------------------------------------------------------------------------------------------

--| Procedimento integra o complemento da operação de PIS/PASEP

procedure pkb_integr_ctcompdoc_pisefd ( est_log_generico      in out nocopy  dbms_sql.number_table
                                      , est_ctcompdoc_pisefd  in out nocopy  ct_comp_doc_pis%rowtype
                                      , ev_cpf_cnpj_emit      in             varchar2
                                      , ev_cod_st             in             cod_st.cod_st%type
                                      , ev_cod_bc_cred_pc     in             base_calc_cred_pc.cd%type
                                      , ev_cod_cta            in             plano_conta.cod_cta%type
                                      , en_multorg_id         in             mult_org.id%type );

-------------------------------------------------------------------------------------------------------

--| Procedimento integra o complemento da operação de COFINS - Campos Flex Field

procedure pkb_integr_ctcompdoccofefd_ff ( est_log_generico      in out nocopy  dbms_sql.number_table
                                        , en_ctcompdoccofins_id in             ct_comp_doc_cofins.id%type
                                        , ev_atributo           in             varchar2
                                        , ev_valor              in             varchar2
                                        , en_multorg_id         in             mult_org.id%type );

-------------------------------------------------------------------------------------------------------

--| Procedimento integra o complemento da operação de COFINS

procedure pkb_integr_ctcompdoc_cofinsefd ( est_log_generico        in out nocopy  dbms_sql.number_table
                                         , est_ctcompdoc_cofinsefd in out nocopy  ct_comp_doc_cofins%rowtype
                                         , ev_cpf_cnpj_emit        in             varchar2
                                         , ev_cod_st               in             cod_st.cod_st%type
                                         , ev_cod_bc_cred_pc       in             base_calc_cred_pc.cd%type
                                         , ev_cod_cta              in             plano_conta.cod_cta%type
                                         , en_multorg_id           in             mult_org.id%type );

-------------------------------------------------------------------------------------------------------

--| Procedimento integra o processo referenciado

procedure pkb_integr_ctprocrefefd ( est_log_generico in out nocopy dbms_sql.number_table
                                  , est_ctprocrefefd in out nocopy ct_proc_ref%rowtype
                                  , en_cd_orig_proc  in            orig_proc.cd%type );

-------------------------------------------------------------------------------------------------------

--| Procedimento integra a informação fiscal do CT

procedure pkb_integr_ctinfor_fiscal ( est_log_generico      in out nocopy  dbms_sql.number_table
                                    , est_ctinfor_fiscal    in out nocopy  ctinfor_fiscal%rowtype
                                    , ev_cod_obs            in             varchar2
                                    , en_multorg_id         in             mult_org.id%type
                                    );
                                    
-------------------------------------------------------------------------------------------------------

--| Procedimento integra os ajustes e informacões de valores provenientes de documento fiscal

procedure pkb_integr_ct_inf_prov ( est_log_generico      in out nocopy  dbms_sql.number_table
                                 , est_ct_inf_prov       in out nocopy  ct_inf_prov%rowtype
                                 , ev_cod_aj             in             varchar2 
                                 );

-------------------------------------------------------------------------------------------------------

-- Procedure que consiste os dados do Conhecimento de Transporte

procedure pkb_consiste_cte ( est_log_generico     in out nocopy  dbms_sql.number_table
                           , en_conhectransp_id   in             Conhec_Transp.Id%TYPE );
                           
-------------------------------------------------------------------------------------------------------

-- Procedimento para gravar o log/alteração dos conhecimentos de transporte

procedure pkb_inclui_log_conhec_transp( en_conhectransp_id in conhec_transp.id%type
                                      , ev_resumo          in log_conhec_transp.resumo%type
                                      , ev_mensagem        in log_conhec_transp.mensagem%type
                                      , en_usuario_id      in neo_usuario.id%type
                                      , ev_maquina         in varchar2 );

-------------------------------------------------------------------------------------------------------

--| Procedimento Valida o Conhecimento de Transporte conforme ID

procedure pkb_validar ( en_conhectransp_id in conhec_transp.id%type );

-------------------------------------------------------------------------------------------------------
-- Função para validar os conhecimentos de transporte - utilizada nas rotinas de validações da GIA, Sped Fiscal e Contribuições
function fkg_valida_cte ( en_empresa_id      in  empresa.id%type
                        , ed_dt_ini          in  date
                        , ed_dt_fin          in  date
                        , ev_obj_referencia  in  log_generico_ct.obj_referencia%type -- processo que acessa a função: sped ou gia
                        , en_referencia_id   in  log_generico_ct.referencia_id%type ) -- identificador do processo que acessar: sped ou gia
         return boolean;

-------------------------------------------------------------------------------------------------------

procedure pkb_ret_multorg_id( est_log_generico       in out nocopy  dbms_sql.number_table
                            , ev_cod_mult_org        in             mult_org.cd%type
                            , ev_hash_mult_org       in             mult_org.hash%type
                            , sn_multorg_id          in out nocopy  mult_org.id%type
                            , ev_obj_referencia      in             log_generico_ct.obj_referencia%type
                            , en_referencia_id       in             log_generico_ct.referencia_id%type);

-------------------------------------------------------------------------------------------------------

-- Procedimento valida o mult org de acordo com o COD e o HASH das tabelas Flex-Field

procedure pkb_val_atrib_multorg ( est_log_generico   in out nocopy  dbms_sql.number_table
                                , ev_obj_name        in             VARCHAR2
                                , ev_atributo        in             VARCHAR2
                                , ev_valor           in             VARCHAR2
                                , sv_cod_mult_org    out            VARCHAR2
                                , sv_hash_mult_org   out            VARCHAR2
                                , ev_obj_referencia  in             log_generico_ct.obj_referencia%type
                                , en_referencia_id   in             log_generico_ct.referencia_id%type
                                );

-------------------------------------------------------------------------------------------------------
--| Procedimento integra os impostos retidos
procedure pkb_integr_ctimpretefd ( est_log_generico        in out nocopy  dbms_sql.number_table
                                 , est_ctimpretefd         in out nocopy  conhec_transp_imp_ret%rowtype
                                 , ev_cpf_cnpj_emit        in             varchar2
                                 , ev_cod_imposto          in             tipo_imposto.cd%type
                                 , ev_cd_tipo_ret_imp      in             tipo_ret_imp.cd%type
                                 , ev_cod_receita          in             tipo_ret_imp_receita.cod_receita%type
                                 , en_multorg_id           in             mult_org.id%type );

-------------------------------------------------------------------------------------------------------
--| Procedimento integra os impostos retidos - Campos Flex Field
procedure pkb_integr_ctimpretefd_ff ( est_log_generico   in out nocopy dbms_sql.number_table
                                    , en_ctimpretefd_id  in            conhec_transp_imp_ret.id%type
                                    , ev_atributo        in            varchar2
                                    , ev_valor           in            varchar2
                                    , en_multorg_id      in            mult_org.id%type );

-------------------------------------------------------------------------------------------------------
-- Procedimento Integra as Informações relativas ao diferencial de aliquota
procedure pkb_integr_ct_dif_aliq ( est_log_generico           in out nocopy dbms_sql.number_table
                                 , est_row_ct_dif_aliq        in out nocopy ct_dif_aliq%rowtype
                                 , en_conhectransp_id         in            Conhec_Transp.id%TYPE );
--								 
end pk_csf_api_d100;
/
