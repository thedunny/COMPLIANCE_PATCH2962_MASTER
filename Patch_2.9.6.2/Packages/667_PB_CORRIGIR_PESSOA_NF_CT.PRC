CREATE OR REPLACE PROCEDURE CSF_OWN.PB_CORRIGIR_PESSOA_NF_CT
IS
-- Procedimento para atualizar o pessoa_id das tabelas NOTA_FISCAL e CONHEC_TRANSP
--
-- Em 04/02/2021  - João Carlos 2.9.5-5
-- Redmine #75477 - Ajuste para vincular pessoa de documentos fiscais Vinculado a ficha #75807
--                - Adicionado um novo atributo para o código do participante intermediário COD_PART_INTERMED
--
-- Em 04/02/2021  - João Carlos 2.9.5-5
-- Redmine #75477 - Ajuste para vincular pessoa de documentos fiscais
--                - No procedimento que faz a validação da pessoa, adicionar uma novo trecho que busca o NOTAFISCAL_ID pelo COD_PART
--                - na NOTA_FISCAL_RELAC e os documentos localizados devem ter o PESSOA_ID preenchido se o mesmo estiver nulo;
--                - Depois de atualizar o documento fiscal com o PESSOA_ID, apagar o registro da NOTA_FISCAL_RELAC e assim evitar
--                - que o registro seja pego numa futura validação da mesma pessoa.
--
vn_fase              NUMBER := 0;
--
CURSOR C_NF_CTE_RELAC IS
      SELECT 'NOTA_FISCAL_RELAC' ORIGEM,
             C.ID NF_CTE_RELAC_ID,
             C.NOTAFISCAL_ID NFE_CTE_ID,
             C.ATRIBUTO,
             C.VALOR,
             P.ID PESSOA_ID
        FROM NOTA_FISCAL N
            ,NOTA_FISCAL_RELAC C
            ,PESSOA P
       WHERE 1 = 1
         AND N.EMPRESA_ID IN (SELECT E.ID
                                FROM EMPRESA E
                               WHERE E.MULTORG_ID IN (SELECT MULTORG_ID
                                                        FROM MULT_ORG MO
                                                            ,EMPRESA E
                                                       WHERE MO.ID = E.MULTORG_ID
                                                         AND E.ID  = N.EMPRESA_ID))
         AND C.NOTAFISCAL_ID = N.ID
         AND C.VALOR         = P.COD_PART
         AND C.ATRIBUTO        IN ('COD_PART', 'COD_PART_INTERMED')
         AND ROWNUM         <= 50
      UNION
      SELECT 'CONHEC_TRANSP_RELAC' ORIGEM,
             CTR.ID NF_CTE_RELAC_ID,
             CTR.CONHECTRANSP_ID NFE_CTE_ID,
             CTR.ATRIBUTO,
             CTR.VALOR,
             P.ID PESSOA_ID
        FROM CONHEC_TRANSP T
            ,CONHEC_TRANSP_RELAC CTR
            ,PESSOA P
       WHERE 1=1
         AND T.EMPRESA_ID IN (SELECT E.ID
                                FROM EMPRESA E
                               WHERE E.MULTORG_ID IN (SELECT MULTORG_ID
                                                        FROM MULT_ORG MO
                                                            ,EMPRESA E
                                                       WHERE MO.ID = E.MULTORG_ID
                                                         AND E.ID  = T.EMPRESA_ID))
         AND CTR.CONHECTRANSP_ID = T.ID
         AND CTR.VALOR           = P.COD_PART
         AND CTR.ATRIBUTO        = 'COD_PART'
         AND ROWNUM             <= 50;
--
BEGIN
    --
    vn_fase := 1;
    --
    FOR REC IN C_NF_CTE_RELAC LOOP
      --
      vn_fase := 2;
      --
      -- Verifica se o registro é referente a uma Nota Fiscal ou um Conhecimento de Transporte
      IF REC.ORIGEM = 'NOTA_FISCAL_RELAC' THEN
        --
        vn_fase := 3;
        --
        IF REC.ATRIBUTO = 'COD_PART' THEN
          BEGIN
            -- Atualiza o registro de Nota Fiscal com o ID do Participante
            UPDATE NOTA_FISCAL N
               SET N.PESSOA_ID = REC.PESSOA_ID
             WHERE N.ID        = REC.NFE_CTE_ID;
          EXCEPTION
            WHEN OTHERS THEN
              NULL;
          END;
          --
          COMMIT;
          --
          vn_fase := 3.1;
          --
          PK_VALIDA_AMBIENTE.PKB_LER_NOTA_FISCAL(EN_NOTAFISCAL_ID => REC.NFE_CTE_ID);
          --
          vn_fase := 3.2;
          --
          BEGIN
            -- Exclui o registro da tabela de relacionamento, pois não será utilizado mais
            DELETE NOTA_FISCAL_RELAC
             WHERE ID = REC.NF_CTE_RELAC_ID;
          EXCEPTION
            WHEN OTHERS THEN
              NULL;
          END;
          --
          COMMIT;
          --
        ELSIF REC.ATRIBUTO = 'COD_PART_INTERMED' THEN
          BEGIN
            -- Atualiza o registro de Nota Fiscal com o ID do Participante
            UPDATE NOTA_FISCAL N
               SET N.PESSOA_ID_INTERMED = REC.PESSOA_ID
             WHERE N.ID                 = REC.NFE_CTE_ID;
          EXCEPTION
            WHEN OTHERS THEN
              NULL;
          END;
          --
          COMMIT;
          --
          vn_fase := 3.3;
          --
          PK_VALIDA_AMBIENTE.PKB_LER_NOTA_FISCAL(EN_NOTAFISCAL_ID => REC.NFE_CTE_ID);
          --
          vn_fase := 3.4;
          --
          BEGIN
            -- Exclui o registro da tabela de relacionamento, pois não será utilizado mais
            DELETE NOTA_FISCAL_RELAC
             WHERE ID = REC.NF_CTE_RELAC_ID;
          EXCEPTION
            WHEN OTHERS THEN
              NULL;
          END;
          --
          COMMIT;
          --
        END IF;
      ELSIF REC.ORIGEM = 'CONHEC_TRANSP_RELAC' THEN
        --
        vn_fase := 4;
        --
        BEGIN
          -- Atualiza o registro de Nota Fiscal com o ID do Participante
          UPDATE CONHEC_TRANSP N
             SET N.PESSOA_ID = REC.PESSOA_ID
           WHERE N.ID        = REC.NFE_CTE_ID;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
        --
        COMMIT;
        --
        vn_fase := 4.1;
        --
        PK_VALIDA_AMBIENTE_CT.PKB_LER_CONHEC_TRANSP(EN_CONHECTRANSP_ID => REC.NFE_CTE_ID);
        --
        vn_fase := 4.2;
        --
        BEGIN
          -- Exclui o registro da tabela de relacionamento, pois não será utilizado mais
          DELETE CONHEC_TRANSP_RELAC
           WHERE ID = REC.NF_CTE_RELAC_ID;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
        --
        COMMIT;
        --
      END IF;
    END LOOP;
    --
    vn_fase := 99;
    --
EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20101, 'Erro ao executar procedure PB_CORRIGIR_PESSOA_NF_CT de Atualização de pessoa_id na NF/CT. Fase (' || vn_fase || '): '||sqlerrm);
END PB_CORRIGIR_PESSOA_NF_CT;
/