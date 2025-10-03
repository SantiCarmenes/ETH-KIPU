//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*///////////////////////
        Imports
///////////////////////*/
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ETHDevPackNFT} from "src/m3-projects/ETHDevPackNFT.sol";

/*///////////////////////
        Libraries
///////////////////////*/
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*///////////////////////
        Interfaces
///////////////////////*/
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title Contrato Donations
 * @notice Este es un contrato con fines educativos.
 * @author i3arba - 77 Innovation Labs
 * @custom:security No usar en producción.
 */
contract DonationsV2 is Ownable {
    /*///////////////////////
        DECLARACIÓN DE TIPOS
    ///////////////////////*/
    using SafeERC20 for IERC20;

    /*///////////////////////
    Variables
    ///////////////////////*/
    ///@notice variable inmutable para almacenar la dirección de USDC
    IERC20 immutable i_usdc;
    ///@notice variable inmutable para almacenar el NFT de EDP
    ETHDevPackNFT immutable i_edp;

    ///@notice variable constante para almacenar el latido (heartbeat) del Data Feed
    uint16 constant ORACLE_HEARTBEAT = 3600;
    ///@notice variable constante para almacenar el factor de decimales
    uint256 constant DECIMAL_FACTOR = 1 * 10 ** 20;
    ///@notice variable constante para almacenar el umbral de recompensa
    uint32 constant REWARD_THRESHOLD = 1000*10**6;

    ///@notice variable para almacenar la dirección del Chainlink Feed
    AggregatorV3Interface public s_feeds; //0x694AA1769357215DE4FAC081bf1f309aDC325306 Ethereum ETH/USD
    ///@notice mapping para almacenar el valor donado por usuario
    mapping(address usuario => uint256 valor) public s_doacoes;

    /*///////////////////////
    Eventos
    ////////////////////////*/
    ///@notice evento emitido cuando se realiza una nueva donación
    event DonationsV2_DoacaoRecebida(address donante, uint256 valor);
    ///@notice evento emitido cuando se realiza un retiro
    event DonationsV2_SaqueRealizado(address receptor, uint256 valor);
    ///@notice evento emitido cuando el Chainlink Feed es actualizado
    event DonationsV2_ChainlinkFeedUpdated(address feed);

    /*///////////////////////
    Errores
    ///////////////////////*/
    ///@notice error emitido cuando una transacción falla
    error DonationsV2_TrasacaoFalhou(bytes error);
    ///@notice error emitido cuando el retorno del oráculo es incorrecto
    error KipuBank_OracleCompromised();
    ///@notice error emitido cuando la última actualización del oráculo supera el heartbeat
    error KipuBank_StalePrice();

    /*///////////////////////
            Funciones
    ///////////////////////*/
    constructor(address _feed, address _usdc, address _owner) Ownable(_owner) {
        s_feeds = AggregatorV3Interface(_feed);
        i_usdc = IERC20(_usdc);
        i_edp = new ETHDevPackNFT(_owner, _owner, address(this));
    }

    /**
     * @notice función para recibir donaciones
     * @dev esta función debe sumar el valor donado por cada dirección a lo largo del tiempo
     * @dev esta función necesita emitir un evento informando la donación.
     */
    function doeETH() external payable {
        uint256 amountDonatedInUSD = convertEthInUSD(msg.value);

        s_doacoes[msg.sender] = s_doacoes[msg.sender] + amountDonatedInUSD;

        emit DonationsV2_DoacaoRecebida(msg.sender, amountDonatedInUSD);

        if(s_doacoes[msg.sender] > REWARD_THRESHOLD && i_edp.balanceOf(msg.sender) == 0 ){
            _mintRewardNFT(msg.sender);
        }
    }

    /**
     * @notice función externa para recibir depósitos de tokens ERC20
     * @notice emite un evento cuando la transacción es exitosa.
     * @param _usdcAmount la cantidad a ser donada.
     */
    function doeUSDC(uint256 _usdcAmount) external {
        s_doacoes[msg.sender] += _usdcAmount;

        emit DonationsV2_DoacaoRecebida(msg.sender, _usdcAmount);

        i_usdc.safeTransferFrom(msg.sender, address(this), _usdcAmount);
    }

    /**
     * @notice función para retirar el valor de las donaciones
     * @notice el valor del retiro debe ser el valor del saldo disponible
     * @dev solo el beneficiario puede retirar
     */
    function saque() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        uint256 usdcBalance = i_usdc.balanceOf(address(this));

        if (ethBalance > 0) {
            emit DonationsV2_SaqueRealizado(msg.sender, ethBalance);

            _transferirEth(ethBalance);
        }
        if (usdcBalance > 0) {
            emit DonationsV2_SaqueRealizado(msg.sender, usdcBalance);

            i_usdc.safeTransfer(msg.sender, usdcBalance);
        }
    }

    /**
     * @notice función para actualizar el Chainlink Price Feed
     * @param _feed la nueva dirección del Price Feed
     * @dev debe ser llamada solo por el propietario
     */
    function setFeeds(address _feed) external onlyOwner {
        s_feeds = AggregatorV3Interface(_feed);

        emit DonationsV2_ChainlinkFeedUpdated(_feed);
    }

    /**
     * @notice función interna para realizar la conversión de decimales de ETH a USDC
     * @param _ethAmount la cantidad de ETH a ser convertida
     * @return convertedAmount_ el resultado del cálculo.
     */
    function convertEthInUSD(uint256 _ethAmount) internal view returns (uint256 convertedAmount_) {
        convertedAmount_ = (_ethAmount * chainlinkFeed()) / DECIMAL_FACTOR;
    }

    /**
     * @notice función para consultar el precio en USD del ETH
     * @return ethUSDPrice_ el precio provisto por el oráculo.
     * @dev esta es una implementación simplificada, y no sigue completamente las buenas prácticas
     */
    function chainlinkFeed() internal view returns (uint256 ethUSDPrice_) {
        (, int256 ethUSDPrice,, uint256 updatedAt,) = s_feeds.latestRoundData();

        if (ethUSDPrice == 0) revert KipuBank_OracleCompromised();
        if (block.timestamp - updatedAt > ORACLE_HEARTBEAT) revert KipuBank_StalePrice();

        ethUSDPrice_ = uint256(ethUSDPrice);
    }

    /**
     * @notice función privada para realizar la transferencia de ether
     * @param _valor El valor a ser transferido
     * @dev necesita revertir si falla
     */
    function _transferirEth(uint256 _valor) private {
        (bool sucesso, bytes memory erro) = msg.sender.call{value: _valor}("");
        if (!sucesso) revert DonationsV2_TrasacaoFalhou(erro);
    }

    /**
     * @notice función privada para recompensar benefactores con un NFT único
     * @param _user la dirección que recibirá el NFT
     */
    function _mintRewardNFT(address _user) private {
        i_edp.safeMint(_user);
    }
}