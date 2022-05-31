
--Function A
Create or Replace Function a_distancia_linear(lat1 in number, long1 in number, lat2 in number, long2 in number, Radius in number Default 3963) Return FLOAT IS
  
  DegToRad float := 57.29577951;
  resMetros number;
  resMilhaNautica number;
  
Begin
    resMetros := (NVL(Radius,0) * ACOS((sin(NVL(lat1,0) / DegToRad) * SIN(NVL(lat2,0) / DegToRad)) +
                 (COS(NVL(lat1,0) / DegToRad) * COS(NVL(lat2,0) / DegToRad) *
                  COS(NVL(long2,0) / DegToRad - NVL(long1,0)/ DegToRad))));
    resMilhaNautica := resMetros * 1852; 
    
    return resMilhaNautica;
End;
/
  
  
--Function B
Create or Replace Function b_viagem_atual_da_embarcacao (shipId in number) Return number IS
  
   idViagem Viagens.Cod_Viagem%type;
   dataPartida Viagens.Data_partida%type;
   CODE NUMBER;
   
Begin

    Begin
        Select e.cod_embarque into CODE
        From Embarcacoes e
        Where e.cod_embarque = shipid;
        
    Exception
        When NO_DATA_FOUND then
              RAISE_APPLICATION_ERROR(-20501,'A Embarca��o com id ' || shipId || ' n�o existe.');    
    End;
    
    Select Cod_Viagem into idViagem
    From Viagens v,Embarcacoes e
    Where e.Cod_Embarque = v.Cod_Embarque and v.Cod_Embarque = CODE and  v.data_partida = (Select Max(vi.Data_Partida)
                                                                                           From Viagens vi,Embarcacoes em
                                                                                           Where em.Cod_Embarque = vi.Cod_Embarque and vi.Cod_Embarque = CODE);
   
    return idViagem; 
End;
/
show erros;

--Function C
Create or Replace Function c_zona_da_localizacao (lati number, longi in number) Return number IS

   idZona Zonas.Cod_Zona%type;
   
Begin
    select Z.Cod_Zona into idZona
    From Historico_De_localizacoes hdl, Zonas z
    Where hdl.Cod_Zona = z.Cod_Zona and hdl.latitude = lati and hdl.longitude = longi;
     
    return idZona;
End;
/
show erros;

--Function D
Create or Replace Function d_zona_atual_da_embarcacao (shipid in number) Return number IS

idZona Zonas.Cod_Zona%type;
CODE Number;
   
Begin

    Begin
        Select e.cod_embarque into CODE
        From Embarcacoes e
        Where e.cod_embarque = shipid;
        
    Exception
        When NO_DATA_FOUND then
              RAISE_APPLICATION_ERROR(-20501,'A Embarca��o com id ' || shipId || ' n�o existe.');    
    End;
    
    Select z.Cod_Zona into idZona
    From Embarcacoes e, Zonas z
    Where e.Cod_Zona = z.Cod_Zona and e.cod_embarque = CODE;
     
    return idZona;
          
End;
/
show erros;

--Function E
Create or Replace Function e_tempo_que_esta_na_zona (shipid number, zoneID number) Return Number IS
    
    CODE NUMBER;
    CODZ NUMBER;
    tempo_zona_min Number;
    
Begin

    Begin
        Select e.cod_embarque into CODE
        From Embarcacoes e
        Where e.cod_embarque = shipid;
        
    Exception
        When NO_DATA_FOUND then
              RAISE_APPLICATION_ERROR(-20501,'A Embarca��o com id ' || shipId || ' n�o existe.');    
    End;
    
    Begin
        Select z.cod_zona into CODZ
        From Zonas z
        Where z.cod_zona = zoneID;
        
    Exception
        When NO_DATA_FOUND then
              RAISE_APPLICATION_ERROR(-20502,'A Zona com id ' || zoneID || ' n�o existe.');    
    End;
    
    --outside chega
    
    
    Select (sysdate - min(hdl.data_hora)) * 24 * 60 into tempo_zona_min
    From Embarcacoes e, Zonas z, HISTORICO_DE_LOCALIZACOES hdl
    Where e.cod_zona = z.cod_zona and z.cod_zona = hdl.cod_zona and e.cod_embarque = CODE and z.cod_zona = CODZ
    ;
        
    return tempo_zona_min;
End;
/
show erros;

--Function F
Create Function f_num_embarcacoes_na_zona(zoneID number) Return Number IS
    
     CODZ NUMBER;
     NEmbarcacoes Number;
     
Begin

    Begin
        Select z.cod_zona into CODZ
        From Zonas z
        Where z.cod_zona = zoneID;
    
    Exception
        When NO_DATA_FOUND then
            RAISE_APPLICATION_ERROR(-20502,'A Zona com id ' || zoneID || ' n�o existe.');
    End;
    
    Select count(e.cod_embarque) into NEmbarcacoes
    From Embarcacoes e, Zonas z
    Where e.cod_zona = z.cod_zona and z.cod_zona = CODZ;
    
    return NEmbarcacoes;
--O que � areas de influ�ncia do canal ->TODAS AS EMBARCACOES QUE N�O EST�O EM OUTSIDE OU SEJA SO OS QUE ENTRATAM DENTRO DO CANAL

End;
/
show erros;

--Function G
Create or Replace Function g_proxima_ordem_a_executar (shipId number) Return Number IS
    
    CODE NUMBER;
    CODP NUMBER;
Begin
    
    Begin
        Select e.cod_embarque into CODE
        From Embarcacoes e
        Where e.cod_embarque = shipid;
        
    Exception
        When NO_DATA_FOUND then
              RAISE_APPLICATION_ERROR(-20501,'A Embarca��o com id ' || shipId || ' n�o existe.');    
    End;
    
    Begin
        Select pdp.cod_passagem into CODP
        From Embarcacoes e, PEDIDOS_DE_PASSAGEM pdp, Viagens v
        Where e.cod_embarque =v.cod_embarque and v.cod_viagem = pdp.cod_viagem and e.cod_embarque = CODE and 
        pdp.data_pedido = (Select max(pdp.data_pedido)
                           From Embarcacoes e, PEDIDOS_DE_PASSAGEM pdp, Viagens v
                           Where e.cod_embarque =v.cod_embarque and v.cod_viagem = pdp.cod_viagem and e.cod_embarque = CODE);
    Exception
        When NO_DATA_FOUND then
            RAISE_APPLICATION_ERROR(-20511,'A Embarca��o com id ' || CODE || ' n�o tem novas ordens');
    End;
    
    return CODP;
End;
/
show erros;

--Procedure H
Create or Replace Procedure h_emite_ordem(shipId NUMBER, orderType NUMBER, execDate DATE) IS
    CODE Number;
Begin
    
    Begin
        Select e.cod_embarque into CODE
        From Embarcacoes e
        Where e.cod_embarque = shipid;
        
    Exception
        When NO_DATA_FOUND then
              RAISE_APPLICATION_ERROR(-20501,'A Embarca��o com id ' || shipId || ' n�o existe.');    
    End;
    
    
    
End;
/
show erros;
--orderType Number? � o Cod_Movimento  associado ao tipo de ordem
--codigo associado ao tipo de ordem , para navega etc

Create or Replace Procedure i_updateGPS(shipID number, latitude number, longitude number) IS
    CODE Number;
Begin

    Begin
        Select e.cod_embarque into CODE
        From Embarcacoes e
        Where e.cod_embarque = shipid;
        
    Exception
        When NO_DATA_FOUND then
              RAISE_APPLICATION_ERROR(-20501,'A Embarca��o com id ' || shipId || ' n�o existe.');    
    End;
    
    
--perguntar ao prodessor se � preciso criar outro c�digo hdl para registar a que est� atualmente    
End;
/
show erros;

--Procedure J
Create or Replace Procedure j_cria_viagem_regresso(shipId number) IS
 CODE NUMBER;
 DOCK NUMBER;
 CODV NUMBER;
 MAXCODV NUMBER;
 CODPARTIDA NUMBER;
 CODCHEGADA NUMBER;
Begin
    Begin
        Select e.cod_embarque into CODE
        From Embarcacoes e
        Where e.cod_embarque = shipid;
        
    Exception
        When NO_DATA_FOUND then
              RAISE_APPLICATION_ERROR(-20501,'A Embarca��o com id ' || shipId || ' n�o existe.');    
    End;
    
    Select count(*), v.cod_viagem, v.cod_port_part,v.cod_port_cheg into DOCK, CODV, CODPARTIDA, CODCHEGADA
    From embarcacoes e, viagens v, Zonas z, Portos p
    Where e.cod_embarque = v.cod_embarque and e.cod_zona = z.cod_zona and e.cod_embarque = CODE and upper(v.estado) = 'DOCK' 
    and upper(z.tipo) = 'PORTO' and
    v.data_partida = (Select max(v.data_partida)
                      From Embarcacoes e, Viagens v
                      Where e.cod_embarque = v.cod_embarque and e.cod_embarque = CODE) 
    Group by v.cod_viagem, v.cod_port_part, v.cod_port_cheg;
    
    If DOCK = 0 then
        RAISE_APPLICATION_ERROR(-20515,'A Embarca��o com id ' || shipId || ' n�o est� DOCKED num porto.');
    Else
        Select max(cod_viagem) into MAXCODV
        From viagens v;
        
        INSERT INTO VIAGENS VALUES(MAXCODV + 1,CODPARTIDA,CODE,CODCHEGADA,sysdate,0,'UNDOCK',0,0,0,sysdate);
    End if;
End;
/
show erros;

--Procedure K
Create or Replace Procedure K_emite_autorizacao_n_ships (zoneId in Number, n in Number) IS

  CODZ Zonas.Cod_Zona%Type;
  tipoZona Zonas.Nome_Zona%Type;
  countEmbarcacoes Zonas.Quant_Embarcacoes%Type;
  counter NUMBER;
  counter := n;
  
  cursor embarcacoesParadas is
    Select e.cod_embarque, (sysdate - pdp.data_pedido), a.cod_registo 
    From Embarcacoes e, Zonas z, Viagens v, PEDIDOS_DE_PASSAGEM pdp, Autorizacoes a
    Where e.cod_zona = z.cod_zona and e.cod_embarque = v.cod_embarque and pdp.cod_viagem = v.cod_viagem and pdp.cod_passagem = a.cod_passagem
    and z.cod_zona = zoneID and upper(v.estado) = 'PARADO' and upper(a.estado) = 'PENDING'
    Group by e.cod_embarque
    Order by 2 DESC;
    
  cursor embarcacoesNavegar is
    Select e.cod_embarque, e.comprimento
    From Embarcacoes e, Zonas z, Viagens v
    Where e.cod_zona = z.cod_zona and z.cod_zona = zoneID and e.cod_embarque = v.cod_embarque
    and upper(v.estado) = 'NAVEGAR'
    Order by 2 DESC;
    
-- No caso das navega��es a navegar como dar a autoriza��o se n�o existe pedido de passagem -> Dar autoriza��o a todas as que est�o NA GATE sempre que entrar na zona a embarcacao tem que emitir um pedido esta no enunciados

Begin
  Begin
        Select z.cod_zona into CODZ
        From Zonas z
        Where z.cod_zona = zoneId;
    
    Exception
        When NO_DATA_FOUND then
            RAISE_APPLICATION_ERROR(-20502,'A Zona com id ' || zoneID || ' n�o existe.');
    End;
    
  
  Begin
      Select upper(z.tipo) into tipoZona
      From Zonas z
      Where z.cod_Zona = CODZ;
      
      if tipoZona <> 'GATE' then 
          RAISE_APPLICATION_ERROR(-20513,'A Zona com id ' || zoneID || ' n�o � do tipo GATE.');
  
      End if;
  End;
  
  Begin
    select Quant_Embarcacoes into countEmbarcacoes
    From Embarcacoes e, Zonas z
    Where e.Cod_Zona = z.Cod_Zona and
          z.Cod_Zona = ZoneId;
    
    if countEmbarcacoes = 0 then
      RAISE_APPLICATION_ERROR(-20514,'A Zona com id ' || zoneID || ' n�o tem embarca��es.');
      
    End if;
    
    FOR PARADAS in embarcacoesParadas
    LOOP
      
      UPDATE ACOES
      Set DATA_FIM = sysdate,
          DURACAO = sysdate - data_inicio_ordem
      WHERE cod_registo = PARADAS.cod_registo;
      
      --counter = counter - 1;
    END LOOP;
    
    End;  
End;
/
show erros;

ALTER TABLE ACOES
MODIFY DURACAO NUMBER(10);



--ALINEA Q
/*Identificar se o sistema permite por exemplo introduzir uma data de chegada de viagem superior � data de partida etc...

