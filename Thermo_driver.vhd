-- Mateusz Krawczyk 212525;
-- Tak tak wszystkie komentarze pis³a³em w celu zrozumienia tematu
-- ¯ycze mi³ej lektury :)


----------------UWAGI--------------------------
--pomyœleæ nad optymalizacj¹
--obracowaæ sposób wypraowadzania danej tempretatury
--opracowaæ jak zrobiæ obs³uge wyœwietlacza lcd;
-----------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

entity Thermo_driver is
    Port ( One_wire : inout  STD_LOGIC;
           temp : out  STD_LOGIC_vector(15 downto 0);
			  reset: in std_logic;
           clk : in  STD_LOGIC);
end Thermo_driver;

architecture a_Thermo_driver of Thermo_driver is

-- sygna³y do do probkowania czêstotliwoœæ 50MHz
signal count_1u	: 	std_logic_vector (15 downto 0) :=(others =>'0');
signal clk_in		: 	std_logic :='0';

--maszyna stanów, r -zapis, w - odczyt
type	state_type	is	(s0, s1, s2, s3, s4, s5, s6, s7, w0, w1, w2, w3, r0, r1, r2, r3); 
signal state		:	state_type;

signal temperature	:	std_logic_vector(15 downto 0); -- czytany sygna³ temperatuty
signal i					:	integer range 0 to 50000;-- licznik czasowy mikro sekund

--signal long			:	std_logic_vector(5 downto 0) := (others =>'0');
begin

-- g³ówny proces wyzwalany tatkowaniem sygna³u wewnêtrznego o okresie 1
main: process(reset,clk_in)

variable temp_bit : integer range 0 to 15;--miejsce bitu dla sygna³y odczytu temperatury 
variable command	: integer range 0 to 100;-- zmienna okreœlaj¹ca kolejne bity rozkazów

begin
	if(clk_in'event and clk_in ='1') then
		i<= i+1;
		case state is
-----------------------------------------------------------------------------------------------------------------			
			-- INICJALIZACJA						(resetowanie ok 480us, highZ ok 100us oczekiwanie na sygna³ obecnoœæi, jeœli na One wire ='0' przechodzimy dalej)
			when s0 =>	
						One_wire<= '0'; 			--ustawienie sygna³u low do póŸniejszego odczekania
						i<=0;							--resetowanie licznika czsu;
						state<=s1;					--przejœcie do nastêpnego stanu
						
			when s1 =>
						if(i=500) then				--odczekiwanie 500us 
							One_wire<='Z';			--wystawienie wysokiej impedancji by oczekiwaæ na sygna³ obecnoœci
							i<=0;						--resetowanie licznika czasu
							state<=s2;				--przejœcie do nastêpnego stanu
						else
							state<=s1;
						end if;
						
			when s2 =>
					if(i=100) then					--oczekiwanie na pewnoœæ w pojawieniu siê sygna³u obecnoœæi (po ok 15-60us (wiêc czekamy 100us), trwa od 60-240us)
						i<=0;							--resetowanie licznika czasu
						state<=s3;					--przejœcie do nastêpnego stanu
					else
						state<=s2;
					end if;
					
			when s3 =>
						if(One_wire= '0') then 	--Jeœli doczekaliœmy siê stany niskiego na od niewolnika
							i<=0;						--resetowanie licznika czasu
							state<=s4;				--przejœcie do nastêpnego stanu
						else
							state<=s0;				-- jeœli nie doczekaliœmy siê stanu niskiego to idziemy od pocz¹tku
							i<=0;
						end if;
						
			when s4 =>
						if(i=300) then				-- odczekanie 300us przed przyst¹pieniem do ROM COMMANDS
							i<=0;
							state<=s5;
						else
							state<=s4;
						end if;
						
-----------------------------ZMIANA ROZDZIELCZOŒCI CZYTANIA----------------------------------------------------------------------					
		--ROM COMMANDS								--Zabawa z szukaniem i rozpoznawaniem urz¹dzenia, pozdrawiam Mateusz Krawczyk ":)"
														--a jednak nie. Mamy tylko jeden termometrt to mo¿na przejœæ odrazu do skip rom, który pod³aczy nam wszystkie obiekty na linie (w tym przypadku jeden)
														--PRESY£ ODBYWA SIÊ OD NAJMNIEJ ZNACZ¥CEGO BITU
														
			--Przesy³anie komendy Skip ROM:	CC Hex czyli 11001100					-
			when s5 =>
				if		(command=0)	then	command:=1;		state<=w0;						--1	--Komenda przes³ania 0 do termometru;
				elsif	(command=1)	then	command:=2; 	state<=w0;						--2
				elsif	(command=2)	then	command:=3; 	state<=w2;	One_wire<='0';	--3	--Komenda przes³ania 1 do termometrul
				elsif	(command=3)	then	command:=4; 	state<=w2;	One_wire<='0';	--4
				elsif	(command=4)	then	command:=5; 	state<=w0;						--5
				elsif	(command=5)	then	command:=6; 	state<=w0;						--6
				elsif	(command=6)	then	command:=7; 	state<=w2;	One_wire<='0';	--7
				elsif	(command=7)	then	command:=8; 	state<=w2;	One_wire<='0';	--8
									
		--FUNCTION COMMANDS						--Komendy które wyp³ywaja na dzia³anie wybranego elementu na szynie 1-wire;
			
			--Przeslanie Komendy Write Scratchpad: 4E hex czyli 01001110				--Komenda ta pozwala na ustawienie CR(configuration rejestr) oraz alarmy
																											
				elsif	(command=8)	then	command:=9;		state<=w0;						--1	--Komenda przes³ania 0 do termometru;
				elsif	(command=9)	then	command:=10;	state<=w2;	One_wire<='0';	--2
				elsif	(command=10)then	command:=11; 	state<=w2;	One_wire<='0';	--3	--Komenda przes³ania 1 do termometrul
				elsif	(command=11)then	command:=12; 	state<=w2;	One_wire<='0';	--4
				elsif	(command=12)then	command:=13; 	state<=w0;						--5
				elsif	(command=13)then	command:=14; 	state<=w0;						--6
				elsif	(command=14)then	command:=15; 	state<=w2;	One_wire<='0';	--7
				elsif	(command=15)then	command:=16; 	state<=w0;						--8
				
			--Zapisanie rejestrów programowalnych												--[CR][Tl][Th] -- rejestry które bêdziemy chcieli zapisaæ
			
			--Byte TH 00000000;																		--brak alarmu wysokiego
				elsif	(command=16)then	command:=17;	state<=w0;						--1
				elsif	(command=17)then	command:=18;	state<=w0;						--2
				elsif	(command=18)then	command:=19; 	state<=w0;						--3	
				elsif	(command=19)then	command:=20; 	state<=w0;						--4
				elsif	(command=20)then	command:=21; 	state<=w0;						--5
				elsif	(command=21)then	command:=22; 	state<=w0;						--6
				elsif	(command=22)then	command:=23; 	state<=w0;						--7
				elsif	(command=23)then	command:=24; 	state<=w0;						--8
				
			--Byte TL 00000000;																		--brak alarmu niskiego
				elsif	(command=24)then	command:=25;	state<=w0;						--1
				elsif	(command=25)then	command:=26;	state<=w0;						--2
				elsif	(command=26)then	command:=27; 	state<=w0;						--3	
				elsif	(command=27)then	command:=28; 	state<=w0;						--4
				elsif	(command=28)then	command:=29; 	state<=w0;						--5
				elsif	(command=29)then	command:=30; 	state<=w0;						--6
				elsif	(command=30)then	command:=31; 	state<=w0;						--7
				elsif	(command=31)then	command:=32; 	state<=w0;						--8
				
			--Byte CR 00011111;																		--zapisanie bity R1 i R0 na 0 (ustawienie na rozdzielczoœæ 9bitow¹)
				elsif	(command=32)then	command:=33;	state<=w2;	One_wire<='0';	--1
				elsif	(command=33)then	command:=34;	state<=w2;	One_wire<='0';	--2
				elsif	(command=34)then	command:=35; 	state<=w2;	One_wire<='0';	--3	
				elsif	(command=35)then	command:=36; 	state<=w2;	One_wire<='0';	--4
				elsif	(command=36)then	command:=37; 	state<=w2;	One_wire<='0';	--5
				elsif	(command=37)then	command:=38; 	state<=w0;						--6
				elsif	(command=38)then	command:=39; 	state<=w0;						--7
				elsif	(command=39)then	command:=40; 	state<=w0;						--8
				
			--Powrót do inicjalizacji!!!
				elsif	(command=40)then	command:=41;	state<=s0;	One_wire<='Z';	--powrót do inicjalizacji
				end if;
				
				
-------------------------------------KONWERSIA TEMPERATURY--------------------------------------------------------
		--ROM COMMANDS																				--ponowne przes³anie komedny skip ROM
		
			--Przesy³anie komendy Skip ROM:	CC Hex czyli 11001100					
				if		(command=41)then	command:=42;	state<=w0;						--1	--Komenda przes³ania 0 do termometru;
				elsif	(command=42)then	command:=43; 	state<=w0;						--2
				elsif	(command=43)then	command:=44; 	state<=w2;	One_wire<='0';	--3	--Komenda przes³ania 1 do termometrul
				elsif	(command=44)then	command:=45; 	state<=w2;	One_wire<='0';	--4
				elsif	(command=45)then	command:=46; 	state<=w0;						--5
				elsif	(command=46)then	command:=47; 	state<=w0;						--6
				elsif	(command=47)then	command:=48; 	state<=w2;	One_wire<='0';	--7
				elsif	(command=48)then	command:=49; 	state<=w2;	One_wire<='0';	--8
				
		--FUNCTION COMMANDS
			
			--Przes³anie komendy Convert T:	44Hex czyli 01000100
				elsif	(command=49)then	command:=50;	state<=w0;						--1	--Komenda przes³ania 0 do termometru;
				elsif	(command=50)then	command:=51; 	state<=w0;						--2
				elsif	(command=51)then	command:=52; 	state<=w2;	One_wire<='0';	--3	--Komenda przes³ania 1 do termometrul
				elsif	(command=52)then	command:=53; 	state<=w0;						--4
				elsif	(command=53)then	command:=54; 	state<=w0;						--5
				elsif	(command=54)then	command:=55; 	state<=w0;						--6
				elsif	(command=55)then	command:=56; 	state<=w2;	One_wire<='0';	--7
				elsif	(command=56)then	command:=57; 	state<=w0;						--8
				
			--Odczekanie czasu konwertowania
				elsif (command=57)then	command:=58;	state<=s6; One_wire<='Z';	i<=0;	--przejœcie do oczekiwania konwersji
				end if;
				
				
----------------------------------------ODCZYTANIE TEMPERATURY-------------------------------------------------------
		--ROM COMMANDS																				--ponowne przes³anie komedny skip ROM
			--Przesy³anie komendy Skip ROM:	CC Hex czyli 11001100					
				if		(command=58)then	command:=59;	state<=w0;						--1	--Komenda przes³ania 0 do termometru;
				elsif	(command=59)then	command:=60; 	state<=w0;						--2
				elsif	(command=60)then	command:=61; 	state<=w2;	One_wire<='0';	--3	--Komenda przes³ania 1 do termometrul
				elsif	(command=61)then	command:=62; 	state<=w2;	One_wire<='0';	--4
				elsif	(command=62)then	command:=63; 	state<=w0;						--5
				elsif	(command=63)then	command:=64; 	state<=w0;						--6
				elsif	(command=64)then	command:=65; 	state<=w2;	One_wire<='0';	--7
				elsif	(command=65)then	command:=66; 	state<=w2;	One_wire<='0';	--8
				end if;
		
		--FUNCTION COMMANDS
			--Przesy³anie komendy Read Scratchpad: BE hex	czyli	10111110
				if		(command=66)then	command:=67;	state<=w0;						--1	--Komenda przes³ania 0 do termometru;
				elsif	(command=67)then	command:=68; 	state<=w2;	One_wire<='0';	--2
				elsif	(command=68)then	command:=69; 	state<=w2;	One_wire<='0';	--3	--Komenda przes³ania 1 do termometru
				elsif	(command=69)then	command:=70; 	state<=w2;	One_wire<='0';	--4
				elsif	(command=70)then	command:=71; 	state<=w2;	One_wire<='0';	--5
				elsif	(command=71)then	command:=72; 	state<=w2;	One_wire<='0';	--6
				elsif	(command=72)then	command:=73; 	state<=w0;						--7
				elsif	(command=73)then	command:=74; 	state<=w2;	One_wire<='0';	--8
				
				elsif	(command=74)then	command:=80; 	state<=s7;						--przejœcie do odczytu temperatury
				end if;
				
				
---------------------------CZYTANIE TEMPERATURY ZAPISANEJ W TERMOMETRZE----------------------------------------------	
			when s7=>
				if		(command=80)then	command:=81;	state<=r0;	temp_bit:=0;		One_wire<='0';	--1
				elsif	(command=81)then	command:=82;	state<=r0;	temp_bit:=1;		One_wire<='0';	--2
				elsif	(command=82)then	command:=83;	state<=r0;	temp_bit:=2;		One_wire<='0';	--3
				elsif	(command=83)then	command:=84;	state<=r0;	temp_bit:=3;		One_wire<='0';	--4
				elsif	(command=84)then	command:=85;	state<=r0;	temp_bit:=4;		One_wire<='0';	--5
				elsif	(command=85)then	command:=86;	state<=r0;	temp_bit:=5;		One_wire<='0';	--6
				elsif	(command=86)then	command:=87;	state<=r0;	temp_bit:=6;		One_wire<='0';	--7
				elsif	(command=87)then	command:=88;	state<=r0;	temp_bit:=7;		One_wire<='0';	--8
				elsif	(command=88)then	command:=89;	state<=r0;	temp_bit:=8;		One_wire<='0';	--9
				elsif	(command=89)then	command:=90;	state<=r0;	temp_bit:=9;		One_wire<='0';	--10
				elsif	(command=90)then	command:=91;	state<=r0;	temp_bit:=10;		One_wire<='0';	--11
				elsif	(command=91)then	command:=92;	state<=r0;	temp_bit:=11;		One_wire<='0';	--12
				elsif	(command=92)then	command:=93;	state<=r0;	temp_bit:=12;		One_wire<='0';	--13
				elsif	(command=93)then	command:=94;	state<=r0;	temp_bit:=13;		One_wire<='0';	--14
				elsif	(command=94)then	command:=95;	state<=r0;	temp_bit:=14;		One_wire<='0';	--15
				elsif	(command=95)then	command:=100;	state<=r0;	temp_bit:=15;		One_wire<='0';	--16
				
				elsif	(command=100)then	i<=0; command:=40;	
				end if;
---------------------------------------------------------------------------------------------------------------------						
		--ODCZYT										-- u¿ywane do odczytywania temperatury ale tak¿e funkcji read rom
			when r0 =>
				state<=r1;
				i<=0;
				
			when r1 =>
				One_wire<='Z';						-- odczekanie 10us z sygna³em wysokiej impedancji
				if(i=10) then						-- po tym czasie powinien pojawiæ siê nam sygna³ który podaje termometr
					i<=0;								--czyli takie nasluchowanie
					state<=r2;
				else
					state<=r1;
				end if;
				
			when r2 =>
				temperature(temp_bit)<= One_wire;--przepisanie  bitu przes³anego przez termomert do rejestru przechowuj¹cego temperature
				state<=r3;							-- przejœcie do kolejnego stanu
				i<=0;									--zresetowanie licznika
				
			when r3 =>
				if(i=55) then						-- odczekanie 55us bo tyle mo¿e trwaæ sygna³ zera podczas czytania
					i<=0;
					state<=s7;						-- przejœcie do stanu w którym odbuwa siê czytanie;
				else 	
					state<=r3;
				end if;
------------------------------------------------------------------------------------------------------------------			
		--ZAPIS										-- Wysy³anie komend za pomocn¹ 1wire, bit po bicie
			
			--wys³anie zera
			when w0 =>
				One_wire<='0';						-- wystawianie stanu low na 80us (od 60us do 120us)
				i<=0;
				if(i=80) then
					One_wire<='Z';					--któtkie wstawienie wysokiej impedancji;
					i<=0;								--resetowanie licznika czasu
					state<=w1;						--przejœcie do nastêpnego stanu;
				else
					state<=w0;						
				end if;
				
			when w1 =>
				state<= s5;							--przejœcie do odczytania kolejnego bitu
				
			--wys³anie jedynki
			when w2 =>
				state<=w3;
				i<=0;								--resetowanie licznika czasu
			
			when w3 =>
				One_wire<='1';						--ustawienie stanu wysokiego na lini
				if(i=80)	then						--odczekanie 80us by zapisa³a siê dana
					i<=0;								--resetowanie licznika czasu
					state<=s5;						--przejœcie do kolejnego bitu
				else
					state<=w3;
				end if;
-----------------------------------------------------------------------------------------------------------------	
		--ODCZEKANIE PO KONWERSJI TEMPERATURY
			when s6 =>
				if(i=800 or One_wire='1') then						--oczekanie 800us;
					state<=s0;
					i<=0;
				else
					state<=s6;
				end if;
-----------------------------------------------------------------------------------------------------------------				
			when others =>
				state<=s0;
		end case;	
	end if;	
end process main;
-----------------------------------------------------------------------------------------------------------------	

-----------------------------------------------------------------------------------------------------------------	
--LICZNIK MIKROSEKUNDOWY
--licznik zliczajacy 1 us by u³atwiæ sobie prace. 
counter: process(clk,reset)
begin
	if(reset ='1')then
		count_1u<= (others =>'0');
	elsif(clk'event and clk='1') then
		if(count_1u ="110001") then
			count_1u<= (others =>'0');
			clk_in<= '1';
		else
			clk_in<='0';
			count_1u<= count_1u+"01";
		end if;
	end if;
end process counter;
-----------------------------------------------------------------------------------------------------------------	
temp<= temperature; 										--wyjœcie

end a_Thermo_driver;

