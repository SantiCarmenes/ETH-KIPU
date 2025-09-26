//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
	*@title Contrato Donations
	*@notice Este es un contrato con fines educativos.
	*@author i3arba - 77 Innovation Labs
	*@custom:security No usar en producción.
*/
contract Donations {

	/*///////////////////////
					Variables
	///////////////////////*/
	///@notice variable inmutable para almacenar la dirección que debe retirar las donaciones
	address immutable i_beneficiario;
	
	///@notice mapping para almacenar el valor donado por usuario
	mapping(address usuario => uint256 valor) public s_doacoes;
	
	/*///////////////////////
						Events
	////////////////////////*/
	///@notice evento emitido cuando se realiza una nueva donación
	event Donations_DoacaoRecebida(address doador, uint256 valor);
	///@notice evento emitido cuando se realiza un retiro
	event Donations_SaqueRealizado(address recebedor, uint256 valor);
	
	/*///////////////////////
						Errors
	///////////////////////*/
	///@notice error emitido cuando falla una transacción
	error Donations_TrasacaoFalhou(bytes erro);
	///@notice error emitido cuando una dirección diferente al beneficiario intenta retirar
	error Donations_SacadorNaoPermitido(address chamador, address beneficiario);
	
	/*///////////////////////
					Functions
	///////////////////////*/
	constructor(address _beneficiario){
		i_beneficiario = _beneficiario;
	}
	
	
	///@notice función para recibir ether directamente
	receive() external payable{}
	fallback() external{}
	
	/**
		*@notice función para recibir donaciones
		*@dev esta función debe sumar el valor donado por cada dirección a lo largo del tiempo
		*@dev esta función debe emitir un evento informando la donación.
	*/
	function doe() external payable {
		s_doacoes[msg.sender] = s_doacoes[msg.sender] += msg.value;
	
		emit Donations_DoacaoRecebida(msg.sender, msg.value);
	}
	
	function saque(uint256 _valor) external {
		if(msg.sender != i_beneficiario) revert Donations_SacadorNaoPermitido(msg.sender, i_beneficiario);
		
		emit Donations_SaqueRealizado(msg.sender, _valor);
		
		_transferirEth(_valor);
	}
	
	/**
		*@notice función privada para realizar la transferencia del ether
		*@param _valor El valor a ser transferido
		*@dev debe revertir si falla
	*/
	function _transferirEth(uint256 _valor) private {
		(bool sucesso, bytes memory erro) = msg.sender.call{value: _valor}("");
		if(!sucesso) revert Donations_TrasacaoFalhou(erro);
	}
}
